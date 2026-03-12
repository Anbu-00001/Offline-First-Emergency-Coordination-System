import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/responder_state_service.dart';

/// FloatingActionButton to toggle between Active and Inactive responder states.
class ResponderToggle extends StatelessWidget {
  const ResponderToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ResponderStateService>(
      builder: (context, stateService, child) {
        return StreamBuilder<ResponderState>(
          initialData: stateService.currentState,
          stream: stateService.stateStream,
          builder: (context, snapshot) {
            final state = snapshot.data ?? ResponderState.inactive;
            final isActive = state == ResponderState.active;

            return FloatingActionButton.extended(
              heroTag: 'responder_toggle',
              onPressed: () => stateService.toggleState(),
              backgroundColor: isActive ? Colors.green : Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              icon: Icon(
                isActive ? Icons.verified_user : Icons.health_and_safety,
              ),
              label: Text(
                isActive ? "Responder Mode Active" : "Become Active Responder",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          },
        );
      },
    );
  }
}
