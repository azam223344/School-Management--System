import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../config/routes/route_constants.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/utils/role_routing.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/providers/auth_provider.dart';

const String _adminSupportPhone = '+923360863737';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthProvider>();
    final theme = Get.find<ThemeProvider>();
    return AnimatedBuilder(
      animation: Listenable.merge([auth, theme]),
      builder: (context, _) {
        final user = auth.user;
        final roleConfig = _roleConfig(auth.role);
        return Scaffold(
          appBar: AppBar(
            leading: const AppBackButton(),
            title: const Text('Profile & Security'),
            actions: [
              IconButton(
                tooltip: 'Dashboard',
                onPressed: () => Get.offNamed(landingRouteForRole(auth.role)),
                icon: const Icon(Icons.dashboard_rounded),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(Responsive.pagePadding(context)),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive.contentMaxWidth(
                    context,
                    desktop: 760,
                    tablet: 760,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeaderCard(
                      name: user?.displayName ?? 'School Admin',
                      email: user?.email ?? '-',
                      verified: user?.emailVerified == true,
                      uid: user?.uid ?? '-',
                      roleLabel: roleConfig.label,
                      gradient: roleConfig.gradient,
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _InfoChip(
                              icon: Icons.security_rounded,
                              label: user?.emailVerified == true
                                  ? 'Email Verified'
                                  : 'Verification Pending',
                            ),
                            _InfoChip(
                              icon: Icons.manage_accounts_rounded,
                              label: 'Role: ${roleConfig.label}',
                            ),
                            const _InfoChip(
                              icon: Icons.school_rounded,
                              label: 'School Management Access',
                            ),
                            const _InfoChip(
                              icon: Icons.support_agent_rounded,
                              label: 'Admin Phone: $_adminSupportPhone',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _RoleOverviewCard(config: roleConfig),
                    const SizedBox(height: 12),
                    Text(
                      'Security',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    _TileButton(
                      icon: Icons.alternate_email_rounded,
                      title: 'Change Email',
                      subtitle: 'Re-authentication required',
                      onTap: () => Get.toNamed(RouteConstants.changeEmail),
                    ),
                    _TileButton(
                      icon: Icons.password_rounded,
                      title: 'Change Password',
                      subtitle: 'Update your password securely',
                      onTap: () => Get.toNamed(RouteConstants.changePassword),
                    ),
                    if (user?.emailVerified != true)
                      _TileButton(
                        icon: Icons.verified_user_rounded,
                        title: 'Verify Email',
                        subtitle: 'Required for protected account actions',
                        onTap: () => Get.toNamed(RouteConstants.verifyEmail),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Preferences',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    _ThemeTile(
                      isDarkMode: theme.isDarkMode,
                      onChanged: theme.toggleTheme,
                    ),
                    const SizedBox(height: 8),
                    if (auth.isAdmin)
                      _TileButton(
                        icon: Icons.admin_panel_settings_rounded,
                        title: 'Role Management',
                        subtitle: 'Assign roles and link student accounts',
                        onTap: () => Get.toNamed(RouteConstants.roleManagement),
                      ),
                    if (auth.isAdmin) const SizedBox(height: 8),
                    Text(
                      'Role Quick Access',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: roleConfig.quickActions
                              .map(
                                (action) => _QuickActionButton(
                                  action: action,
                                  onTap: () => Get.toNamed(action.route),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Session',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    _TileButton(
                      icon: Icons.logout_rounded,
                      title: 'Logout',
                      subtitle: 'Sign out from this device',
                      danger: true,
                      onTap: auth.isLoading
                          ? () {}
                          : () async {
                              await auth.signOut();
                              if (context.mounted) {
                                Get.offAllNamed(RouteConstants.login);
                              }
                            },
                    ),
                    _TileButton(
                      icon: Icons.delete_outline_rounded,
                      title: 'Delete Account',
                      subtitle: 'Permanent action',
                      danger: true,
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            actionsOverflowDirection: VerticalDirection.down,
                            actionsOverflowButtonSpacing: 8,
                            title: const Text('Delete account?'),
                            content: const Text(
                              'This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && context.mounted) {
                          final ok = await auth.deleteAccount();
                          if (ok && context.mounted) {
                            Get.offAllNamed(RouteConstants.login);
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.name,
    required this.email,
    required this.verified,
    required this.uid,
    required this.roleLabel,
    required this.gradient,
  });

  final String name;
  final String email;
  final bool verified;
  final String uid;
  final String roleLabel;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  name.isEmpty ? 'A' : name.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(email, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              Icon(
                verified ? Icons.verified_rounded : Icons.error_outline_rounded,
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Role: $roleLabel',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            'UID: $uid',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RoleOverviewCard extends StatelessWidget {
  const _RoleOverviewCard({required this.config});

  final _RoleProfileConfig config;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(config.icon, color: config.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    config.headline,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(config.description),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: config.capabilities
                  .map(
                    (item) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: config.accent.withValues(alpha: 0.12),
                      ),
                      child: Text(
                        item,
                        style: TextStyle(
                          color: config.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.action, required this.onTap});

  final _RoleQuickAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(action.icon),
      label: Text(action.label),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.isDarkMode, required this.onChanged});

  final bool isDarkMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        value: isDarkMode,
        onChanged: onChanged,
        title: const Text('Dark Theme'),
        subtitle: const Text('Switch between light and dark mode'),
        secondary: const Icon(Icons.dark_mode_outlined),
      ),
    );
  }
}

class _RoleProfileConfig {
  const _RoleProfileConfig({
    required this.label,
    required this.headline,
    required this.description,
    required this.capabilities,
    required this.quickActions,
    required this.icon,
    required this.gradient,
    required this.accent,
  });

  final String label;
  final String headline;
  final String description;
  final List<String> capabilities;
  final List<_RoleQuickAction> quickActions;
  final IconData icon;
  final List<Color> gradient;
  final Color accent;
}

class _RoleQuickAction {
  const _RoleQuickAction({
    required this.label,
    required this.route,
    required this.icon,
  });

  final String label;
  final String route;
  final IconData icon;
}

_RoleProfileConfig _roleConfig(AppRole role) {
  switch (role) {
    case AppRole.admin:
      return const _RoleProfileConfig(
        label: 'Admin',
        headline: 'Full School Control',
        description:
            'You can manage users, modules, classes, teachers, students, and all academic operations.',
        capabilities: [
          'Role Assignment',
          'Module Control',
          'Academic Oversight',
          'System Governance',
        ],
        quickActions: [
          _RoleQuickAction(
            label: 'Role Management',
            route: RouteConstants.roleManagement,
            icon: Icons.admin_panel_settings_rounded,
          ),
          _RoleQuickAction(
            label: 'Students',
            route: RouteConstants.students,
            icon: Icons.school_rounded,
          ),
          _RoleQuickAction(
            label: 'Teachers',
            route: RouteConstants.teachers,
            icon: Icons.badge_rounded,
          ),
          _RoleQuickAction(
            label: 'Classes',
            route: RouteConstants.classes,
            icon: Icons.class_rounded,
          ),
          _RoleQuickAction(
            label: 'Chatbot',
            route: RouteConstants.chatbot,
            icon: Icons.smart_toy_rounded,
          ),
        ],
        icon: Icons.workspace_premium_rounded,
        gradient: [Color(0xFF0F766E), Color(0xFF1D4ED8)],
        accent: Color(0xFF1D4ED8),
      );
    case AppRole.teacher:
      return const _RoleProfileConfig(
        label: 'Teacher',
        headline: 'Teaching Operations',
        description:
            'You can manage assigned class records, attendance, exams, and student outcomes.',
        capabilities: ['Class Tracking', 'Attendance', 'Exams', 'Results'],
        quickActions: [
          _RoleQuickAction(
            label: 'Attendance',
            route: RouteConstants.attendance,
            icon: Icons.fact_check_rounded,
          ),
          _RoleQuickAction(
            label: 'Exams',
            route: RouteConstants.exams,
            icon: Icons.assignment_rounded,
          ),
          _RoleQuickAction(
            label: 'Results',
            route: RouteConstants.results,
            icon: Icons.leaderboard_rounded,
          ),
          _RoleQuickAction(
            label: 'Timetable',
            route: RouteConstants.timetable,
            icon: Icons.schedule_rounded,
          ),
          _RoleQuickAction(
            label: 'Chatbot',
            route: RouteConstants.chatbot,
            icon: Icons.smart_toy_rounded,
          ),
        ],
        icon: Icons.menu_book_rounded,
        gradient: [Color(0xFF0B875B), Color(0xFF0087D0)],
        accent: Color(0xFF0B875B),
      );
    case AppRole.parent:
      return const _RoleProfileConfig(
        label: 'Parent',
        headline: 'Child Progress Monitoring',
        description:
            'You can follow academic progress, fee status, attendance, and announcements.',
        capabilities: [
          'Progress Tracking',
          'Fee Monitoring',
          'Attendance View',
          'Notifications',
        ],
        quickActions: [
          _RoleQuickAction(
            label: 'Results',
            route: RouteConstants.results,
            icon: Icons.leaderboard_rounded,
          ),
          _RoleQuickAction(
            label: 'Fees',
            route: RouteConstants.fees,
            icon: Icons.payments_rounded,
          ),
          _RoleQuickAction(
            label: 'Notifications',
            route: RouteConstants.notifications,
            icon: Icons.notifications_rounded,
          ),
          _RoleQuickAction(
            label: 'Timetable',
            route: RouteConstants.timetable,
            icon: Icons.schedule_rounded,
          ),
          _RoleQuickAction(
            label: 'Chatbot',
            route: RouteConstants.chatbot,
            icon: Icons.smart_toy_rounded,
          ),
        ],
        icon: Icons.family_restroom_rounded,
        gradient: [Color(0xFFE07A00), Color(0xFF0087D0)],
        accent: Color(0xFFE07A00),
      );
    case AppRole.student:
      return const _RoleProfileConfig(
        label: 'Student',
        headline: 'Learning Workspace',
        description:
            'You can review timetable, results, study resources, and school announcements.',
        capabilities: [
          'Study Planning',
          'Result Tracking',
          'Library Access',
          'Notices',
        ],
        quickActions: [
          _RoleQuickAction(
            label: 'Timetable',
            route: RouteConstants.timetable,
            icon: Icons.schedule_rounded,
          ),
          _RoleQuickAction(
            label: 'Results',
            route: RouteConstants.results,
            icon: Icons.leaderboard_rounded,
          ),
          _RoleQuickAction(
            label: 'Library',
            route: RouteConstants.library,
            icon: Icons.local_library_rounded,
          ),
          _RoleQuickAction(
            label: 'Notifications',
            route: RouteConstants.notifications,
            icon: Icons.notifications_rounded,
          ),
          _RoleQuickAction(
            label: 'Chatbot',
            route: RouteConstants.chatbot,
            icon: Icons.smart_toy_rounded,
          ),
        ],
        icon: Icons.school_rounded,
        gradient: [Color(0xFF0067C4), Color(0xFF00A39B)],
        accent: Color(0xFF0067C4),
      );
  }
}

class _TileButton extends StatelessWidget {
  const _TileButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? const Color(0xFFD93025)
        : Theme.of(context).colorScheme.primary;

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
