import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/routes/route_constants.dart';

enum _ModuleAiAction { insights, risks, nextSteps, workflowPlan }

class ModuleAiActionButton extends StatelessWidget {
  const ModuleAiActionButton({super.key, required this.moduleName});

  final String moduleName;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ModuleAiAction>(
      tooltip: 'AI Assist',
      icon: const Icon(Icons.auto_awesome_rounded),
      onSelected: (value) {
        final prompt = switch (value) {
          _ModuleAiAction.insights =>
            'Give me AI insights for $moduleName module for my role.',
          _ModuleAiAction.risks =>
            'What are common risks or mistakes in $moduleName module for my role?',
          _ModuleAiAction.nextSteps =>
            'Suggest the next best actions in $moduleName module for my role.',
          _ModuleAiAction.workflowPlan =>
            'Create a short workflow plan for $moduleName module for my role.',
        };
        Get.toNamed(
          RouteConstants.chatbot,
          arguments: <String, String>{'module': moduleName, 'prompt': prompt},
        );
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _ModuleAiAction.insights,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.insights_rounded),
            title: Text('AI Insights'),
          ),
        ),
        PopupMenuItem(
          value: _ModuleAiAction.risks,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.warning_amber_rounded),
            title: Text('Risk Check'),
          ),
        ),
        PopupMenuItem(
          value: _ModuleAiAction.nextSteps,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.playlist_add_check_rounded),
            title: Text('Next Actions'),
          ),
        ),
        PopupMenuItem(
          value: _ModuleAiAction.workflowPlan,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.route_rounded),
            title: Text('Workflow Plan'),
          ),
        ),
      ],
    );
  }
}
