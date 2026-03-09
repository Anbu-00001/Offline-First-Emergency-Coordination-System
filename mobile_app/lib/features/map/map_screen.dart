import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:async';

import '../../core/map/map_diagnostics.dart';
import '../../data/repositories/incident_repository.dart';
import '../../models/models.dart' as models;
import '../messaging/messaging_screen.dart';
import 'map_service.dart';

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
  bool _tileUrlResolved = false;
  bool _tilesLoading = true;
  Timer? _tileLoadTimer;
  final MapController _mapController = MapController();

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
  }

  @override
  void dispose() {
    _tileLoadTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initTileUrl() async {
    final mapService = context.read<MapService>();
    debugPrint('MapScreen: Resolving tile URL...');
    final url = await mapService.resolveTileUrl();
    debugPrint('MapScreen: Tile URL resolved: $url');

    if (mounted) {
      setState(() {
        _tileUrl = url;
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
            onTap: () => _showIncidentDetails(cluster.first.id),
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

  void _showIncidentDetails(String id) async {
    final repo = context.read<IncidentRepository>();
    final incident = await repo.getIncident(id);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
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
              Text('Incident: ${incident.type}',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              _buildDetailRow(Icons.flag, 'Status', incident.status),
              _buildDetailRow(Icons.priority_high, 'Priority', incident.priority),
              _buildDetailRow(Icons.person, 'Reporter', incident.reporter_id),
              _buildDetailRow(Icons.location_on, 'Location',
                  '${incident.lat.toStringAsFixed(4)}, ${incident.lon.toStringAsFixed(4)}'),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(Icons.visibility, 'View', () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Viewing incident details')));
                  }),
                  _buildActionButton(Icons.assignment_ind, 'Assign', () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Assign responder')));
                  }),
                  _buildActionButton(Icons.navigation, 'Navigate', () {
                    Navigator.pop(ctx);
                    _mapController.move(
                      LatLng(incident.lat, incident.lon), 15,
                    );
                  }),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 12,
            )),
          ],
        ),
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
                      _showIncidentDetails(i.id);
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

  void _centerOnMyLocation() {
    _mapController.move(const LatLng(0, 0), 2);
  }

  /// Show debug panel with tile diagnostics.
  void _showDebugPanel() {
    final summary = MapDiagnostics.getSummary();
    final logs = MapDiagnostics.getLogEntries();

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
                  const Text('Logs',
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
                        initialCenter: const LatLng(0, 0),
                        initialZoom: 2.0,
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
                          userAgentPackageName: 'org.openrescue.app',
                          maxZoom: 19,
                          tileBuilder: (context, tileWidget, tile) {
                            // Tile loaded successfully
                            return tileWidget;
                          },
                        ),
                        MarkerLayer(
                          markers: _buildMarkers(),
                        ),
                      ],
                    );
                  },
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
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateIncidentForm(),
        child: const Icon(Icons.add_location_alt),
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
                client_id: 'device_123',
                sequence_num: DateTime.now().millisecondsSinceEpoch,
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
