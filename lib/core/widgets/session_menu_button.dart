import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../config/routes/route_constants.dart';
import '../utils/role_routing.dart';
import '../../features/auth/providers/auth_provider.dart';

enum _SessionAction { home, profile, chatbot, logout }

class SessionMenuButton extends StatelessWidget {
  const SessionMenuButton({super.key, this.showHome = false});

  final bool showHome;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_SessionAction>(
      tooltip: 'Session',
      icon: const Icon(Icons.manage_accounts_outlined),
      onSelected: (value) async {
        switch (value) {
          case _SessionAction.home:
            Get.offNamed(
              landingRouteForRole(context.read<AuthProvider>().role),
            );
            return;
          case _SessionAction.profile:
            Get.toNamed(RouteConstants.profile);
            return;
          case _SessionAction.chatbot:
            Get.toNamed(RouteConstants.chatbot);
            return;
          case _SessionAction.logout:
            await context.read<AuthProvider>().signOut();
            if (!context.mounted) return;
            Get.offAllNamed(RouteConstants.login);
            return;
        }
      },
      itemBuilder: (_) => [
        if (showHome)
          const PopupMenuItem(
            value: _SessionAction.home,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.home_rounded),
              title: Text('Home'),
            ),
          ),
        const PopupMenuItem(
          value: _SessionAction.profile,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.person_outline_rounded),
            title: Text('Profile'),
          ),
        ),
        const PopupMenuItem(
          value: _SessionAction.chatbot,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.smart_toy_outlined),
            title: Text('Chatbot'),
          ),
        ),
        const PopupMenuItem(
          value: _SessionAction.logout,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout_rounded, color: Color(0xFFD93025)),
            title: Text(
              'Logout',
              style: TextStyle(
                color: Color(0xFFD93025),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
