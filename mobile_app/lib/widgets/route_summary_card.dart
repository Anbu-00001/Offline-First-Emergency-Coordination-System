import 'package:flutter/material.dart';
import '../models/route_result.dart';

/// Card displaying route summary: total distance and ETA.
class RouteSummaryCard extends StatelessWidget {
  final RouteResult route;
  final VoidCallback onClose;
  final VoidCallback onShowSteps;

  const RouteSummaryCard({
    super.key,
    required this.route,
    required this.onClose,
    required this.onShowSteps,
  });

  @override
  Widget build(BuildContext context) {
    final distanceKm = route.distanceMeters / 1000.0;
    final durationMin = (route.durationSeconds / 60.0).ceil();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Distance
            const Icon(Icons.straighten, color: Colors.blue, size: 20),
            const SizedBox(width: 6),
            Text(
              '${distanceKm.toStringAsFixed(1)} km',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 20),
            // ETA
            const Icon(Icons.access_time, color: Colors.orange, size: 20),
            const SizedBox(width: 6),
            Text(
              '$durationMin min',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            // Show steps button
            if (route.steps.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.list_alt, color: Colors.blue),
                onPressed: onShowSteps,
                tooltip: 'Turn-by-turn',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            const SizedBox(width: 8),
            // Close button
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: onClose,
              tooltip: 'Clear route',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
