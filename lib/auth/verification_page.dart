import 'package:flutter/material.dart';
import '../Common/flutter_flow_theme.dart';

class VerificationPendingPage extends StatelessWidget {
  const VerificationPendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Verification Pending', style: theme.headlineMedium),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your account creation request has been received.',
                style: theme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'You will receive an email once your account is verified.',
                style: theme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
