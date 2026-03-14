import 'package:flutter/material.dart';
import '../models/route_result.dart';

/// Scrollable panel showing turn-by-turn navigation instructions.
class NavigationStepsPanel extends StatelessWidget {
  final List<RouteStep> steps;

  const NavigationStepsPanel({
    super.key,
    required this.steps,
  });

  /// Show the panel as a bottom sheet.
  static void show(BuildContext context, List<RouteStep> steps) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => NavigationStepsPanel(steps: steps),
    );
  }

  IconData _iconForInstruction(String instruction) {
    final lower = instruction.toLowerCase();
    if (lower.contains('left')) return Icons.turn_left;
    if (lower.contains('right')) return Icons.turn_right;
    if (lower.contains('arrive')) return Icons.flag;
    if (lower.contains('depart')) return Icons.play_arrow;
    if (lower.contains('roundabout')) return Icons.rotate_right;
    if (lower.contains('u-turn') || lower.contains('uturn')) {
      return Icons.u_turn_left;
    }
    return Icons.straight;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.45,
      maxChildSize: 0.85,
      minChildSize: 0.25,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Navigation Steps (${steps.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              Expanded(
                child: steps.isEmpty
                    ? const Center(
                        child: Text(
                          'No navigation steps available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: steps.length,
                        separatorBuilder: (_, _a) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final step = steps[index];
                          final distanceStr = step.distance >= 1000
                              ? '${(step.distance / 1000).toStringAsFixed(1)} km'
                              : '${step.distance.round()} m';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.withAlpha(30),
                              child: Icon(
                                _iconForInstruction(step.instruction),
                                color: Colors.blue,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              step.instruction,
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: Text(
                              distanceStr,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
