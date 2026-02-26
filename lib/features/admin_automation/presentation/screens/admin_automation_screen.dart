import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/session_menu_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../controllers/admin_automation_controller.dart';

class AdminAutomationScreen extends StatefulWidget {
  const AdminAutomationScreen({super.key});

  @override
  State<AdminAutomationScreen> createState() => _AdminAutomationScreenState();
}

class _AdminAutomationScreenState extends State<AdminAutomationScreen> {
  final AdminAutomationController _controller =
      Get.find<AdminAutomationController>();
  final AuthProvider _auth = Get.find<AuthProvider>();
  bool _bound = false;

  @override
  void dispose() {
    if (Get.isRegistered<AdminAutomationController>()) {
      Get.delete<AdminAutomationController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.user?.uid;
    if (!_bound && uid != null) {
      _bound = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.bind(uid);
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Admin Automation'),
        actions: const [SessionMenuButton(showHome: true)],
      ),
      body: Obx(() {
        if (uid == null) {
          return const Center(child: Text('User session not found.'));
        }
        if (_controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_controller.isLocalMode.value)
                Card(
                  color: Colors.amber.shade100,
                  child: ListTile(
                    leading: const Icon(Icons.cloud_off_rounded),
                    title: const Text('Local mode'),
                    subtitle: Text(
                      _controller.syncError.value ??
                          'Automation metrics may be stale.',
                    ),
                  ),
                ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_graph_rounded, size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Automation readiness score',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        '${(_controller.score.value * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Automated administrative tasks',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ..._controller.recommendations.map((item) {
                        final priorityColor = switch (item.priority) {
                          'High' => Colors.red,
                          'Medium' => Colors.orange,
                          _ => Colors.green,
                        };
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: priorityColor.withValues(
                              alpha: 0.2,
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              color: priorityColor,
                            ),
                          ),
                          title: Text(item.title),
                          subtitle: Text(item.description),
                          trailing: item.route == null
                              ? Text(item.priority)
                              : TextButton(
                                  onPressed: () {
                                    Get.toNamed(item.route!);
                                  },
                                  child: const Text('Open'),
                                ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
