import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/module_ai_action_button.dart';
import '../../../../core/widgets/session_menu_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/notification_item.dart';
import '../controllers/notifications_controller.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationsController _controller =
      Get.find<NotificationsController>();
  final AuthProvider _auth = Get.find<AuthProvider>();
  final ThemeProvider _theme = Get.find<ThemeProvider>();

  String? _boundUid;
  String _search = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = _auth.user?.uid;
    if (uid == null || uid == _boundUid) return;
    _boundUid = uid;
    _controller.bind(uid);
  }

  @override
  void dispose() {
    if (Get.isRegistered<NotificationsController>()) {
      Get.delete<NotificationsController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final pagePadding = Responsive.pagePadding(context);
    final maxWidth = Responsive.contentMaxWidth(context);
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: isDarkMode
                ? 'Switch to light mode'
                : 'Switch to dark mode',
            onPressed: () => _theme.toggleTheme(!isDarkMode),
            icon: Icon(
              isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
          const ModuleAiActionButton(moduleName: 'Notifications'),
          const SessionMenuButton(showHome: true),
        ],
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            if (_controller.isLocalMode.value)
              _buildLocalBanner(
                'Local mode: notifications not synced to cloud.',
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(pagePadding),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildControls(),
                        const SizedBox(height: 12),
                        _buildSummary(),
                        const SizedBox(height: 12),
                        _buildList(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _responsiveDialogContent({required Widget child}) {
    final maxWidth = Responsive.controlWidth(context, preferred: 560);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.68;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
      child: SingleChildScrollView(
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }

  Widget _buildLocalBanner(String fallbackText) {
    return Material(
      color: Colors.amber.shade100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _controller.syncError.value == null
                    ? fallbackText
                    : 'Local mode: ${_controller.syncError.value}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(onPressed: _retrySync, child: const Text('Retry Sync')),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: Responsive.controlWidth(context, preferred: 280),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  labelText: 'Search Notifications',
                  hintText: 'Title or message',
                ),
                onChanged: (value) => setState(() => _search = value),
              ),
            ),
            FilledButton.icon(
              onPressed: _openAddDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Send Notice'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final filtered = _filteredItems;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _StatChip(
              label: 'Total Notices',
              value: _controller.items.length.toString(),
              color: Colors.blue,
            ),
            _StatChip(
              label: 'Visible',
              value: filtered.length.toString(),
              color: Colors.teal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final filtered = _filteredItems;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (filtered.isEmpty)
              const Text('No notifications found.')
            else
              ...filtered.map(
                (item) => ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.notifications_active_rounded),
                  ),
                  title: Text(item.title),
                  subtitle: Text(
                    '${item.message}\n${item.date} | ${_targetTitle(item.targetType, item.targetId)}',
                  ),
                  isThreeLine: true,
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () => _openEditDialog(item),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () => _controller.deleteItem(item.id),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<NotificationItem> get _filteredItems {
    final q = _search.trim().toLowerCase();
    return _controller.items.where((item) {
      if (q.isEmpty) return true;
      return item.title.toLowerCase().contains(q) ||
          item.message.toLowerCase().contains(q);
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _openAddDialog() async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    final dateController = TextEditingController();
    NotificationTargetType targetType = NotificationTargetType.student;
    String? targetId;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          actionsOverflowDirection: VerticalDirection.down,
          actionsOverflowButtonSpacing: 8,
          title: const Text('Send Notification'),
          content: _responsiveDialogContent(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: messageController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Message'),
                ),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(labelText: 'Date'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<NotificationTargetType>(
                  initialValue: targetType,
                  decoration: const InputDecoration(labelText: 'Target Type'),
                  items: const [
                    DropdownMenuItem(
                      value: NotificationTargetType.student,
                      child: Text('Student'),
                    ),
                    DropdownMenuItem(
                      value: NotificationTargetType.teacher,
                      child: Text('Teacher'),
                    ),
                    DropdownMenuItem(
                      value: NotificationTargetType.schoolClass,
                      child: Text('Class'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setDialog(() {
                      targetType = value;
                      targetId = null;
                    });
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: targetId,
                  decoration: const InputDecoration(labelText: 'Target'),
                  items: _targetOptions(targetType)
                      .map(
                        (e) =>
                            DropdownMenuItem(value: e.id, child: Text(e.label)),
                      )
                      .toList(),
                  onChanged: (value) => setDialog(() => targetId = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty ||
                    messageController.text.trim().isEmpty ||
                    dateController.text.trim().isEmpty ||
                    targetId == null) {
                  _showError('Fill all notification fields.');
                  return;
                }
                _controller.addItem(
                  title: titleController.text.trim(),
                  message: messageController.text.trim(),
                  date: dateController.text.trim(),
                  targetType: targetType,
                  targetId: targetId!,
                );
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditDialog(NotificationItem existing) async {
    final titleController = TextEditingController(text: existing.title);
    final messageController = TextEditingController(text: existing.message);
    final dateController = TextEditingController(text: existing.date);
    NotificationTargetType targetType = existing.targetType;
    String? targetId = existing.targetId;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          actionsOverflowDirection: VerticalDirection.down,
          actionsOverflowButtonSpacing: 8,
          title: const Text('Edit Notification'),
          content: _responsiveDialogContent(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: messageController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Message'),
                ),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(labelText: 'Date'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<NotificationTargetType>(
                  initialValue: targetType,
                  decoration: const InputDecoration(labelText: 'Target Type'),
                  items: const [
                    DropdownMenuItem(
                      value: NotificationTargetType.student,
                      child: Text('Student'),
                    ),
                    DropdownMenuItem(
                      value: NotificationTargetType.teacher,
                      child: Text('Teacher'),
                    ),
                    DropdownMenuItem(
                      value: NotificationTargetType.schoolClass,
                      child: Text('Class'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setDialog(() {
                      targetType = value;
                      targetId = null;
                    });
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: targetId,
                  decoration: const InputDecoration(labelText: 'Target'),
                  items: _targetOptions(targetType)
                      .map(
                        (e) =>
                            DropdownMenuItem(value: e.id, child: Text(e.label)),
                      )
                      .toList(),
                  onChanged: (value) => setDialog(() => targetId = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty ||
                    messageController.text.trim().isEmpty ||
                    dateController.text.trim().isEmpty ||
                    targetId == null) {
                  _showError('Fill all notification fields.');
                  return;
                }
                _controller.updateItem(
                  id: existing.id,
                  title: titleController.text.trim(),
                  message: messageController.text.trim(),
                  date: dateController.text.trim(),
                  targetType: targetType,
                  targetId: targetId!,
                );
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  List<_EntityOption> _targetOptions(NotificationTargetType type) {
    switch (type) {
      case NotificationTargetType.student:
        return _controller.students
            .map((e) => _EntityOption(id: e.id, label: 'Student: ${e.name}'))
            .toList();
      case NotificationTargetType.teacher:
        return _controller.teachers
            .map((e) => _EntityOption(id: e.id, label: 'Teacher: ${e.name}'))
            .toList();
      case NotificationTargetType.schoolClass:
        return _controller.classes
            .map((e) => _EntityOption(id: e.id, label: 'Class: ${e.name}'))
            .toList();
    }
  }

  String _targetTitle(NotificationTargetType type, String id) {
    switch (type) {
      case NotificationTargetType.student:
        final item = _controller.students.where((e) => e.id == id).firstOrNull;
        return item == null ? 'Student' : 'Student: ${item.name}';
      case NotificationTargetType.teacher:
        final item = _controller.teachers.where((e) => e.id == id).firstOrNull;
        return item == null ? 'Teacher' : 'Teacher: ${item.name}';
      case NotificationTargetType.schoolClass:
        final item = _controller.classes.where((e) => e.id == id).firstOrNull;
        return item == null ? 'Class' : 'Class: ${item.name}';
    }
  }

  void _retrySync() {
    final uid = _auth.user?.uid;
    if (uid == null) return;
    _controller.retrySync(uid);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }
}

class _EntityOption {
  const _EntityOption({required this.id, required this.label});
  final String id;
  final String label;
}

class _StatChip extends StatelessWidget {
  const _StatChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
