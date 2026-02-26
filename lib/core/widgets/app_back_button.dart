import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../utils/role_routing.dart';
import '../../features/auth/providers/auth_provider.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () async {
        final popped = await Navigator.maybePop(context);
        if (popped || !context.mounted) return;
        Get.offNamed(landingRouteForRole(context.read<AuthProvider>().role));
      },
    );
  }
}
