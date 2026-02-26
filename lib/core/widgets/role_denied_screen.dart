import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_back_button.dart';
import '../../config/routes/route_constants.dart';

class RoleDeniedScreen extends StatelessWidget {
  const RoleDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Access Restricted'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 42),
              const SizedBox(height: 10),
              const Text(
                'This section is not available for your role.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () => Get.offNamed(RouteConstants.profile),
                child: const Text('Go to Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
