import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/module_ai_action_button.dart';
import '../../../../core/widgets/session_menu_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/timetable_item.dart';
import '../controllers/timetable_controller.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final TimetableController _controller = Get.find<TimetableController>();
  final AuthProvider _auth = Get.find<AuthProvider>();
  final ThemeProvider _theme = Get.find<ThemeProvider>();
  String? _boundUid;

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
    if (Get.isRegistered<TimetableController>()) {
      Get.delete<TimetableController>();
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
        title: const Text('Timetable'),
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
          const ModuleAiActionButton(moduleName: 'Timetable'),
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
              _buildLocalBanner('Local mode: timetable not synced to cloud.'),
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
            TextButton(
              onPressed: () {
                final uid = _auth.user?.uid;
                if (uid == null) return;
                _controller.retrySync(uid);
              },
              child: const Text('Retry Sync'),
            ),
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
                  labelText: 'Search Slots',
                  hintText: 'Day, time or subject',
                ),
                onChanged: _controller.updateSearch,
              ),
            ),
            FilledButton.icon(
              onPressed: _openAddDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Slot'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final filtered = _controller.filtered;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Timetable Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (filtered.isEmpty)
              const Text('No timetable slots found.')
            else
              ...filtered.map(
                (item) => ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.schedule_rounded),
                  ),
                  title: Text('${item.day} • ${item.time}'),
                  subtitle: Text(
                    '${item.subject} | ${_controller.className(item.classId)} | ${_controller.teacherName(item.teacherId)}',
                  ),
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

  Future<void> _openAddDialog() async {
    final dayController = TextEditingController();
    final timeController = TextEditingController();
    final subjectController = TextEditingController();
    String? teacherId;
    String? classId;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          actionsOverflowDirection: VerticalDirection.down,
          actionsOverflowButtonSpacing: 8,
          title: const Text('Add Timetable Slot'),
          content: _responsiveDialogContent(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: dayController,
                  decoration: const InputDecoration(labelText: 'Day'),
                ),
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(labelText: 'Time'),
                ),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: teacherId,
                  decoration: const InputDecoration(labelText: 'Teacher'),
                  items: _controller.teachers
                      .map(
                        (e) =>
                            DropdownMenuItem(value: e.id, child: Text(e.name)),
                      )
                      .toList(),
                  onChanged: (v) => setDialog(() => teacherId = v),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: classId,
                  decoration: const InputDecoration(labelText: 'Class'),
                  items: _controller.classes
                      .map(
                        (e) =>
                            DropdownMenuItem(value: e.id, child: Text(e.name)),
                      )
                      .toList(),
                  onChanged: (v) => setDialog(() => classId = v),
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
                if (dayController.text.trim().isEmpty ||
                    timeController.text.trim().isEmpty ||
                    subjectController.text.trim().isEmpty ||
                    teacherId == null ||
                    classId == null) {
                  _showError('Fill all timetable fields.');
                  return;
                }
                _controller.addItem(
                  TimetableItem(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    day: dayController.text.trim(),
                    time: timeController.text.trim(),
                    subject: subjectController.text.trim(),
                    teacherId: teacherId!,
                    classId: classId!,
                  ),
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

  Future<void> _openEditDialog(TimetableItem existing) async {
    final dayController = TextEditingController(text: existing.day);
    final timeController = TextEditingController(text: existing.time);
    final subjectController = TextEditingController(text: existing.subject);
    String? teacherId = existing.teacherId;
    String? classId = existing.classId;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          actionsOverflowDirection: VerticalDirection.down,
          actionsOverflowButtonSpacing: 8,
          title: const Text('Edit Timetable Slot'),
          content: _responsiveDialogContent(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: dayController,
                  decoration: const InputDecoration(labelText: 'Day'),
                ),
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(labelText: 'Time'),
                ),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: teacherId,
                  decoration: const InputDecoration(labelText: 'Teacher'),
                  items: _controller.teachers
                      .map(
                        (e) =>
                            DropdownMenuItem(value: e.id, child: Text(e.name)),
                      )
                      .toList(),
                  onChanged: (v) => setDialog(() => teacherId = v),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: classId,
                  decoration: const InputDecoration(labelText: 'Class'),
                  items: _controller.classes
                      .map(
                        (e) =>
                            DropdownMenuItem(value: e.id, child: Text(e.name)),
                      )
                      .toList(),
                  onChanged: (v) => setDialog(() => classId = v),
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
                if (dayController.text.trim().isEmpty ||
                    timeController.text.trim().isEmpty ||
                    subjectController.text.trim().isEmpty ||
                    teacherId == null ||
                    classId == null) {
                  _showError('Fill all timetable fields.');
                  return;
                }
                _controller.updateItem(
                  TimetableItem(
                    id: existing.id,
                    day: dayController.text.trim(),
                    time: timeController.text.trim(),
                    subject: subjectController.text.trim(),
                    teacherId: teacherId!,
                    classId: classId!,
                  ),
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

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }
}
