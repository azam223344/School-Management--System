import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/session_menu_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../controllers/predictive_analytics_controller.dart';

class PredictiveAnalyticsScreen extends StatefulWidget {
  const PredictiveAnalyticsScreen({super.key});

  @override
  State<PredictiveAnalyticsScreen> createState() =>
      _PredictiveAnalyticsScreenState();
}

class _PredictiveAnalyticsScreenState extends State<PredictiveAnalyticsScreen> {
  final PredictiveAnalyticsController _controller =
      Get.find<PredictiveAnalyticsController>();
  final AuthProvider _auth = Get.find<AuthProvider>();
  bool _bound = false;

  @override
  void dispose() {
    if (Get.isRegistered<PredictiveAnalyticsController>()) {
      Get.delete<PredictiveAnalyticsController>();
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
        title: const Text('Predictive Analytics'),
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
                          'Analytics may not be synced.',
                    ),
                  ),
                ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _SummaryChip(
                    label: 'High Risk',
                    value: _controller.highRiskCount.toString(),
                    color: Colors.red,
                  ),
                  _SummaryChip(
                    label: 'Medium Risk',
                    value: _controller.mediumRiskCount.toString(),
                    color: Colors.orange,
                  ),
                  _SummaryChip(
                    label: 'Low Risk',
                    value: _controller.lowRiskCount.toString(),
                    color: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'At-risk students for early intervention',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_controller.predictions.isEmpty)
                        const Text(
                          'No prediction data available yet. Add classes, attendance, and results first.',
                        )
                      else
                        ..._controller.predictions.map((item) {
                          final color = switch (item.riskBand) {
                            'High' => Colors.red,
                            'Medium' => Colors.orange,
                            _ => Colors.green,
                          };
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withValues(alpha: 0.2),
                              child: Text(
                                item.riskBand.substring(0, 1),
                                style: TextStyle(color: color),
                              ),
                            ),
                            title: Text(
                              '${item.studentName} • ${item.className}',
                            ),
                            subtitle: Text(
                              'Risk ${(item.riskScore * 100).toStringAsFixed(1)}% | Attendance ${(item.attendanceRate * 100).toStringAsFixed(0)}% | Avg ${item.averageScore.toStringAsFixed(1)}\n${item.recommendedIntervention}',
                            ),
                            isThreeLine: true,
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

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}
