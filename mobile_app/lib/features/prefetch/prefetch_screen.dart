import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/map/tile_math.dart';
import '../../features/map/map_service.dart';
import 'prefetch_controller.dart';

/// Screen for managing tile prefetch jobs.
///
/// Accessible from the Map Debug Panel. Allows starting, pausing,
/// resuming, and cancelling tile downloads for offline use.
class PrefetchScreen extends StatefulWidget {
  const PrefetchScreen({super.key});

  @override
  State<PrefetchScreen> createState() => _PrefetchScreenState();
}

class _PrefetchScreenState extends State<PrefetchScreen> {
  final _radiusController = TextEditingController(text: '5000');
  final _minZoomController = TextEditingController(text: '12');
  final _maxZoomController = TextEditingController(text: '16');

  int? _estimatedTiles;
  bool _exceedsLimit = false;

  @override
  void dispose() {
    _radiusController.dispose();
    _minZoomController.dispose();
    _maxZoomController.dispose();
    super.dispose();
  }

  void _updateEstimate() {
    final radius = double.tryParse(_radiusController.text) ?? 5000;
    final minZ = int.tryParse(_minZoomController.text) ?? 12;
    final maxZ = int.tryParse(_maxZoomController.text) ?? 16;

    final controller = context.read<PrefetchController>();
    final estimate = controller.estimateTiles(
      lat: indiaCenter.latitude,
      lon: indiaCenter.longitude,
      radiusMeters: radius,
      minZoom: minZ,
      maxZoom: maxZ,
    );

    setState(() {
      _estimatedTiles = estimate.total;
      _exceedsLimit = estimate.total > kMaxTilesPerJob;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PrefetchController>();
    final progress = controller.progress;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tile Prefetch'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Configuration ────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Prefetch Configuration',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _radiusController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Radius (meters)',
                        hintText: '5000',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.radar),
                      ),
                      onChanged: (_) => _updateEstimate(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minZoomController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Min Zoom',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => _updateEstimate(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _maxZoomController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Max Zoom',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => _updateEstimate(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Estimate
                    if (_estimatedTiles != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _exceedsLimit
                              ? Colors.red.withAlpha(30)
                              : Colors.green.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _exceedsLimit
                                  ? Icons.warning
                                  : Icons.check_circle,
                              color:
                                  _exceedsLimit ? Colors.red : Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Estimated: $_estimatedTiles tiles'
                              '${_exceedsLimit ? ' (exceeds limit of $kMaxTilesPerJob)' : ''}',
                              style: TextStyle(
                                color: _exceedsLimit
                                    ? Colors.red
                                    : Colors.green.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ─── Controls ─────────────────────────────────────────
            if (!controller.hasActiveJob) ...[
              ElevatedButton.icon(
                onPressed: controller.isStarting
                    ? null
                    : () {
                        final radius =
                            double.tryParse(_radiusController.text) ?? 5000;
                        final minZ =
                            int.tryParse(_minZoomController.text) ?? 12;
                        final maxZ =
                            int.tryParse(_maxZoomController.text) ?? 16;

                        controller.startPrefetch(
                          lat: indiaCenter.latitude,
                          lon: indiaCenter.longitude,
                          radiusMeters: radius,
                          minZoom: minZ,
                          maxZoom: maxZ,
                        );
                      },
                icon: controller.isStarting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: Text(controller.isStarting
                    ? 'Starting...'
                    : 'Start Prefetch'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: progress?.status == 'paused'
                          ? controller.resume
                          : controller.pause,
                      icon: Icon(progress?.status == 'paused'
                          ? Icons.play_arrow
                          : Icons.pause),
                      label: Text(progress?.status == 'paused'
                          ? 'Resume'
                          : 'Pause'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: controller.cancel,
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      label: const Text('Cancel',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
            ],

            // ─── Error ────────────────────────────────────────────
            if (controller.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withAlpha(100)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ─── Progress ─────────────────────────────────────────
            if (progress != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Progress',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          _StatusBadge(status: progress.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress.progressFraction,
                          minHeight: 12,
                          backgroundColor: Colors.grey.shade200,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${progress.tilesDone} / ${progress.totalTiles} '
                        '(${(progress.progressFraction * 100).toStringAsFixed(1)}%)',
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _StatChip(
                            label: 'Done',
                            value: '${progress.tilesDone}',
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          _StatChip(
                            label: 'Queued',
                            value: '${progress.tilesQueued}',
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          _StatChip(
                            label: 'Failed',
                            value: '${progress.tilesFailed}',
                            color: Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Job ID: ${progress.jobId}',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // ─── Info ─────────────────────────────────────────────
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('How it works',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                      '• Downloads tile images for a radius around a point\n'
                      '• Tiles stored at: appDir/tiles/{z}/{x}/{y}.png\n'
                      '• Queue persists across app restarts\n'
                      '• Failed tiles retry with exponential backoff\n'
                      '• Max $kMaxTilesPerJob tiles per job (safety limit)\n'
                      '• Concurrency: $kDefaultConcurrency parallel downloads',
                      style: TextStyle(fontSize: 12, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'running' => Colors.green,
      'paused' => Colors.orange,
      'completed' => Colors.blue,
      'cancelled' => Colors.red,
      _ => Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}
