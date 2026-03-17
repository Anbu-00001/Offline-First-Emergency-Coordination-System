import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../core/map/fallback_tile_provider.dart';
import '../../core/map/map_diagnostics.dart';
import '../../core/network/http_logging_override.dart';
import '../../data/repositories/incident_repository.dart';
import '../../models/models.dart' as models;
import '../../models/route_result.dart';
import '../messaging/messaging_screen.dart';
import '../prefetch/prefetch_screen.dart';
import 'map_service.dart';
import '../../widgets/responder_toggle.dart';
import '../../widgets/route_summary_card.dart';
import '../../widgets/navigation_steps_panel.dart';
import '../../controllers/route_controller.dart';
import '../../services/location_service.dart';
import '../../services/geocoding_service.dart';
import '../../services/responder_registry.dart';
import '../../models/geocode_result.dart';
import '../../models/nearby_responder.dart';
import '../../services/responder_state_service.dart';

// Temporarily disabled for tile debugging:
// import 'package:maplibre_gl/maplibre_gl.dart';

/// Represents a cluster of incidents at a specific location.
class _IncidentCluster {
  final double lat;
  final double lon;
  final List<models.Incident> incidents;

  _IncidentCluster({required this.lat, required this.lon, required this.incidents});

  bool get isSingle => incidents.length == 1;
  models.Incident get first => incidents.first;
  int get count => incidents.length;
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<models.Incident> _incidents = [];
  double _currentZoom = 2.0;
  String? _tileUrl;
  String? _tilesDir;
  bool _tileUrlResolved = false;
  bool _tilesLoading = true;
  Timer? _tileLoadTimer;
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  Timer? _locationTimer;

  /// Cluster radius in degrees — adjusts with zoom level.
  double get _clusterRadiusDeg {
    if (_currentZoom >= 14) return 0.001;
    if (_currentZoom >= 12) return 0.005;
    if (_currentZoom >= 10) return 0.02;
    if (_currentZoom >= 8) return 0.05;
    if (_currentZoom >= 6) return 0.2;
    if (_currentZoom >= 4) return 1.0;
    return 3.0;
  }

  @override
  void initState() {
    super.initState();
    _initTileUrl();
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!mounted) return;
      final loc = await context.read<LocationService>().getCurrentLocation();
      if (loc != null && mounted) {
        setState(() => _currentLocation = loc);
      }
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _tileLoadTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initTileUrl() async {
    final mapService = context.read<MapService>();
    debugPrint('MapScreen: Resolving tile URL...');
    final url = await mapService.resolveTileUrl();
    debugPrint('MapScreen: Tile URL resolved: $url');

    final appDir = await getApplicationDocumentsDirectory();
    final tilesDir = p.join(appDir.path, 'tiles');

    if (mounted) {
      setState(() {
        _tileUrl = url;
        _tilesDir = tilesDir;
        _tileUrlResolved = true;
      });

      // Start a 3-second timer to show loading banner if tiles still haven't loaded
      _tileLoadTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && _tilesLoading) {
          setState(() {
            // Mark tiles as loaded since flutter_map handles this differently
            _tilesLoading = false;
          });
        }
      });
    }
  }

  /// Cluster incidents based on proximity at current zoom level.
  List<_IncidentCluster> _clusterIncidents(List<models.Incident> incidents) {
    if (incidents.isEmpty) return [];

    final radius = _clusterRadiusDeg;
    final clusters = <_IncidentCluster>[];
    final used = List<bool>.filled(incidents.length, false);

    for (int i = 0; i < incidents.length; i++) {
      if (used[i]) continue;

      final cluster = <models.Incident>[incidents[i]];
      double latSum = incidents[i].lat;
      double lonSum = incidents[i].lon;
      used[i] = true;

      for (int j = i + 1; j < incidents.length; j++) {
        if (used[j]) continue;
        final dLat = (incidents[j].lat - incidents[i].lat).abs();
        final dLon = (incidents[j].lon - incidents[i].lon).abs();
        if (dLat < radius && dLon < radius) {
          cluster.add(incidents[j]);
          latSum += incidents[j].lat;
          lonSum += incidents[j].lon;
          used[j] = true;
        }
      }

      clusters.add(_IncidentCluster(
        lat: latSum / cluster.length,
        lon: lonSum / cluster.length,
        incidents: cluster,
      ));
    }
    return clusters;
  }

  /// Build flutter_map Marker widgets from clustered incidents.
  List<Marker> _buildMarkers() {
    final clusters = _clusterIncidents(_incidents);
    final markers = <Marker>[];

    for (var cluster in clusters) {
      if (cluster.isSingle) {
        markers.add(Marker(
          point: LatLng(cluster.lat, cluster.lon),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _handleIncidentTap(cluster.first),
            child: Icon(
              _incidentIcon(cluster.first.type),
              color: Colors.red,
              size: 32,
            ),
          ),
        ));
      } else {
        markers.add(Marker(
          point: LatLng(cluster.lat, cluster.lon),
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () => _showClusterDetails(
                cluster.incidents.map((i) => i.id).toList()),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(200),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                '${cluster.count}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ));
      }
    }
    return markers;
  }

  void _handleIncidentTap(models.Incident incident) async {
    final responderState = context.read<ResponderStateService>().currentState;
    if (responderState == ResponderState.active) {
      final locService = context.read<LocationService>();
      final start = await locService.getCurrentLocation();
      if (start != null && mounted) {
        context.read<RouteController>().requestRoute(
          start: start,
          end: LatLng(incident.lat, incident.lon),
        );
        return; // Skip showing details when routing immediately
      }
    }
    _showIncidentDetails(incident.id);
  }

  void _showIncidentDetails(String id) async {
    final repo = context.read<IncidentRepository>();
    final geocoder = context.read<GeocodingService>();
    final incident = await repo.getIncident(id);
    // Remove the impossible null check since GeocodingService.reverse() handles defaults
    // Attempt local reverse geocoding directly inline to ensure BottomSheet starts with data when cached
    GeocodeResult? geocodeCache = await geocoder.reverse(incident.lat, incident.lon);

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow it to expand to content size
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            
            // If cache miss caused slow fetch, re-fetch inside UI tree silently to swap views
            if (geocodeCache == null) {
               geocoder.reverse(incident.lat, incident.lon).then((val) {
                 if (mounted && val != null) {
                    setState(() { geocodeCache = val; });
                 }
               });
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_incidentIcon(incident.type), size: 36, color: Colors.blueAccent),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              incident.type,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Priority: ${incident.priority} | Status: ${incident.status}',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  
                  // Detail Rows
                  _buildDetailRow(Icons.pin_drop, 'Location', 
                    geocodeCache != null ? geocodeCache!.address : 'Fetching exact address...'),
                  
                  if (geocodeCache?.landmark != null)
                    _buildDetailRow(Icons.domain, 'Landmark', geocodeCache!.landmark!),
                  
                  _buildDetailRow(Icons.explore, 'Coordinates', '${incident.lat.toStringAsFixed(5)}, ${incident.lon.toStringAsFixed(5)}'),
                  _buildDetailRow(Icons.person, 'Reporter ID', incident.reporterId),
                  _buildDetailRow(Icons.access_time, 'Reported At', incident.updatedAt.toLocal().toString().split('.')[0]),
                  
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                           Navigator.pop(context);
                           _showAssignResponderSheet(incident);
                        },
                        icon: const Icon(Icons.assignment_ind),
                        label: const Text('Assign'),
                      ),
                      const SizedBox(width: 8),
                      // Optional embedded navigate button, primarily handled by marker tapping when responder is active
                      ElevatedButton.icon(
                        onPressed: () {
                           Navigator.pop(context);
                           _handleIncidentTap(incident); // Force triggering the router protocol
                        },
                        icon: const Icon(Icons.navigation),
                        label: const Text('Navigate'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showAssignResponderSheet(models.Incident incident) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final registry = context.read<ResponderRegistry>();
        return FutureBuilder<List<NearbyResponder>>(
          future: registry.getNearbyResponders(incident.lat, incident.lon),
          builder: (context, snapshot) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Assign Responder', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ))
                  else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No active responders found nearby.'),
                    )
                  else
                    ...snapshot.data!.map((responder) => ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(responder.id),
                          subtitle: Text('${responder.distanceKm.toStringAsFixed(1)} km away'),
                          trailing: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Assigned ${incident.id.replaceAll("inc_", "")} to ${responder.id}')),
                              );
                            },
                            child: const Text('Assign'),
                          ),
                        )),
                        
                  if (snapshot.hasData) const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showClusterDetails(List<String> incidentIds) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final clusterIncidents =
            _incidents.where((i) => incidentIds.contains(i.id)).toList();
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${clusterIncidents.length} Incidents',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...clusterIncidents.take(5).map((i) => ListTile(
                    leading: Icon(_incidentIcon(i.type)),
                    title: Text(i.type),
                    subtitle: Text('${i.status} — ${i.priority}'),
                    onTap: () {
                      Navigator.pop(context);
                      _handleIncidentTap(i);
                    },
                  )),
              if (clusterIncidents.length > 5)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                      '+ ${clusterIncidents.length - 5} more incidents',
                      style: TextStyle(color: Colors.grey[600])),
                ),
            ],
          ),
        );
      },
    );
  }

  IconData _incidentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'medical':
        return Icons.medical_services;
      case 'fire':
        return Icons.local_fire_department;
      case 'flood':
        return Icons.water;
      case 'earthquake':
        return Icons.terrain;
      default:
        return Icons.warning;
    }
  }

  void _openCreateIncidentForm({double? lat, double? lon}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _CreateIncidentForm(initialLat: lat, initialLon: lon);
      },
    );
  }

  void _centerOnMyLocation() async {
    final locService = context.read<LocationService>();
    final loc = await locService.getCurrentLocation();
    if (loc != null && mounted) {
      _mapController.move(loc, 16.0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get current location')),
      );
    }
  }

  /// Show debug panel with tile diagnostics.
  void _showDebugPanel() {
    final summary = MapDiagnostics.getSummary();
    final logs = MapDiagnostics.getLogEntries();
    final httpLogs = LoggingHttpOverrides.getLogs();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('🔧 Map Debug Panel',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  // Show TILESERVER_URL config (debug info)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 120,
                          child: Text('TILESERVER_URL:',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                        Expanded(
                          child: Text(
                            MapService.configuredTileserverUrl ?? '(not set)',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: MapService.configuredTileserverUrl != null
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...summary.entries.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text('${e.key}:',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            ),
                            Expanded(
                              child: Text(e.value,
                                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                            ),
                          ],
                        ),
                      )),
                  const Divider(height: 24),
                  const Text('Tile Diagnostics Logs',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (logs.isEmpty)
                    const Text('No log entries yet',
                        style: TextStyle(color: Colors.grey, fontSize: 12))
                  else
                    ...logs.reversed.take(20).map((log) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Text(log,
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
                        )),
                  const Divider(height: 24),
                  const Text('HTTP Overrides Logs (Last 20)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (httpLogs.isEmpty)
                    const Text('No HTTP logs caught',
                        style: TextStyle(color: Colors.grey, fontSize: 12))
                  else
                    ...httpLogs.reversed.take(20).map((log) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Text(log,
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
                        )),
                  const Divider(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PrefetchScreen()),
                        );
                      },
                      icon: const Icon(Icons.download_for_offline),
                      label: const Text('Tile Prefetch'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<IncidentRepository>();
    final mapService = context.watch<MapService>();

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: _showDebugPanel,
          child: Row(
            children: [
              const Text('OpenRescue Map'),
              if (mapService.isUsingMBTiles) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(50),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('OFFLINE',
                      style: TextStyle(fontSize: 10, color: Colors.green,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _centerOnMyLocation,
            tooltip: 'My Location',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _showDebugPanel,
            tooltip: 'Debug Panel',
          ),
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MessagingScreen()));
            },
          ),
        ],
      ),
      body: !_tileUrlResolved
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Resolving tile source...'),
                ],
              ),
            )
          : Stack(
              children: [
                StreamBuilder<List<models.Incident>>(
                  stream: repo.watchIncidents(),
                  builder: (context, streamSnapshot) {
                    if (streamSnapshot.hasData) {
                      _incidents = streamSnapshot.data!;
                    }

                    debugPrint('MapScreen: Building FlutterMap with tile URL: $_tileUrl');

                    return FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: indiaCenter,
                        initialZoom: indiaDefaultZoom,
                        minZoom: 4,
                        maxZoom: 18,
                        // Restrict panning so map center stays within India bounds
                        cameraConstraint: CameraConstraint.containCenter(
                          bounds: indiaBounds,
                        ),
                        onPositionChanged: (position, hasGesture) {
                          final newZoom = position.zoom;
                          if ((newZoom - _currentZoom).abs() > 0.5) {
                            _currentZoom = newZoom;
                            // Markers rebuild automatically via setState
                            if (mounted) setState(() {});
                          }
                        },
                        onLongPress: (tapPos, latLng) {
                          _openCreateIncidentForm(
                            lat: latLng.latitude,
                            lon: latLng.longitude,
                          );
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: _tileUrl!,
                          userAgentPackageName: 'org.openrescue.mobile',
                          maxZoom: 19,
                          tileProvider: _tilesDir != null 
                              ? FallbackFileTileProvider(tilesDir: _tilesDir!)
                              : NetworkTileProvider(),
                        ),
                        StreamBuilder<ResponderState>(
                          stream: context.read<ResponderStateService>().stateStream,
                          initialData: context.read<ResponderStateService>().currentState,
                          builder: (context, snapshot) {
                            final isActive = snapshot.data == ResponderState.active;
                            if (isActive && _currentLocation != null) {
                              return CircleLayer(
                                circles: [
                                  CircleMarker(
                                    point: _currentLocation!,
                                    color: Colors.blue.withAlpha(50),
                                    borderColor: Colors.blue,
                                    borderStrokeWidth: 2,
                                    useRadiusInMeter: true,
                                    radius: 5000, // 5km radius
                                  ),
                                  CircleMarker(
                                    point: _currentLocation!,
                                    color: Colors.blue,
                                    radius: 8,
                                  ),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        StreamBuilder<RouteResult?>(
                          stream: context.read<RouteController>().routeStream,
                          builder: (context, snapshot) {
                            final routeResult = snapshot.data;
                            final routePoints = routeResult?.geometry ?? [];

                            // Auto-fit camera when a new route arrives
                            if (routeResult != null && routePoints.length >= 2) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                final bounds = LatLngBounds.fromPoints(routePoints);
                                _mapController.fitCamera(
                                  CameraFit.bounds(
                                    bounds: bounds,
                                    padding: const EdgeInsets.all(40),
                                  ),
                                );
                              });
                            }

                            return PolylineLayer(
                              polylines: [
                                if (routePoints.isNotEmpty)
                                  Polyline(
                                    points: routePoints,
                                    strokeWidth: 5,
                                    color: Colors.blue,
                                  ),
                              ],
                            );
                          },
                        ),
                        MarkerLayer(
                          markers: _buildMarkers(),
                        ),
                      ],
                    );
                  },
                ),
                // Route Summary Card
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: StreamBuilder<RouteResult?>(
                    stream: context.read<RouteController>().routeStream,
                    builder: (context, snapshot) {
                      final routeResult = snapshot.data;
                      if (routeResult == null) return const SizedBox.shrink();
                      return RouteSummaryCard(
                        route: routeResult,
                        onClose: () {
                          context.read<RouteController>().clearRoute();
                        },
                        onShowSteps: () {
                          NavigationStepsPanel.show(context, routeResult.steps);
                        },
                      );
                    },
                  ),
                ),
                // Visual tile source overlay (bottom-left)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(160),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Tile source: ${_tileUrl != null && _tileUrl!.length > 40 ? '${_tileUrl!.substring(0, 40)}...' : _tileUrl}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace'),
                    ),
                  ),
                ),
                  // Loading banner
                  if (_tilesLoading && _tileUrlResolved)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.orange.withAlpha(220),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Tiles loading… (source: ${context.read<MapService>().fallbackMode})',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.bug_report, color: Colors.white, size: 18),
                              onPressed: _showDebugPanel,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Deep Diagnostic Tile Fetcher removed per user request
                ],
              ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const ResponderToggle(),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add_incident',
            onPressed: () => _openCreateIncidentForm(),
            child: const Icon(Icons.add_location_alt),
          ),
        ],
      ),
    );
  }
}

class _CreateIncidentForm extends StatefulWidget {
  final double? initialLat;
  final double? initialLon;

  const _CreateIncidentForm({this.initialLat, this.initialLon});

  @override
  State<_CreateIncidentForm> createState() => _CreateIncidentFormState();
}

class _CreateIncidentFormState extends State<_CreateIncidentForm> {
  final _typeController = TextEditingController(text: 'Medical');
  final _priorityController = TextEditingController(text: 'High');
  late final TextEditingController _latController;
  late final TextEditingController _lonController;

  @override
  void initState() {
    super.initState();
    _latController = TextEditingController(
        text: widget.initialLat?.toStringAsFixed(6) ?? '');
    _lonController = TextEditingController(
        text: widget.initialLon?.toStringAsFixed(6) ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Report New Incident',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (widget.initialLat != null && widget.initialLon != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Location: ${widget.initialLat!.toStringAsFixed(4)}, '
                    '${widget.initialLon!.toStringAsFixed(4)}',
                    style: const TextStyle(color: Colors.green, fontSize: 13),
                  ),
                ],
              ),
            ),
          TextField(
              controller: _typeController,
              decoration: const InputDecoration(labelText: 'Type')),
          TextField(
              controller: _priorityController,
              decoration: const InputDecoration(labelText: 'Priority')),
          if (widget.initialLat == null) ...[
            TextField(
                controller: _latController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Latitude')),
            TextField(
                controller: _lonController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Longitude')),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save Incident'),
            onPressed: () async {
              final repo = context.read<IncidentRepository>();
              final nav = Navigator.of(context);
              final scaffold = ScaffoldMessenger.of(context);

              final lat = widget.initialLat ??
                  double.tryParse(_latController.text) ??
                  (Random().nextDouble() * 180) - 90;
              final lon = widget.initialLon ??
                  double.tryParse(_lonController.text) ??
                  (Random().nextDouble() * 360) - 180;

              final dto = models.IncidentCreateDto(
                type: _typeController.text,
                lat: lat,
                lon: lon,
                priority: _priorityController.text,
                status: 'New',
                clientId: 'device_123',
                sequenceNum: DateTime.now().millisecondsSinceEpoch,
              );
              await repo.createIncident(dto);

              nav.pop();
              scaffold.showSnackBar(
                  const SnackBar(content: Text('Incident created & queued for sync')));

              repo.pushLocalChanges();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
