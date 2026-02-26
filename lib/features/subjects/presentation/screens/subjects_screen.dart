import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/module_ai_action_button.dart';
import '../../../../core/widgets/session_menu_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/subject_item.dart';
import '../controllers/subjects_controller.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final SubjectsController _controller = Get.find<SubjectsController>();
  final AuthProvider _auth = Get.find<AuthProvider>();
  final ThemeProvider _theme = Get.find<ThemeProvider>();

  String? _boundUid;
  String _search = '';
  String? _selectedClassId;

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
    if (Get.isRegistered<SubjectsController>()) {
      Get.delete<SubjectsController>();
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
        title: const Text('Subjects'),
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
          const ModuleAiActionButton(moduleName: 'Subjects'),
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
              Material(
                color: Colors.amber.shade100,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off_rounded),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _controller.syncError.value == null
                              ? 'Local mode: subjects not synced to cloud.'
                              : 'Local mode: ${_controller.syncError.value}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: _retrySync,
                        child: const Text('Retry Sync'),
                      ),
                    ],
                  ),
                ),
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
                        _buildSubjectsList(),
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

  Widget _buildControls() {
    final classes = _controller.classes;
    if (_selectedClassId != null &&
        classes.where((c) => c.id == _selectedClassId).isEmpty) {
      _selectedClassId = null;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: Responsive.controlWidth(context, preferred: 280),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  labelText: 'Search Subjects',
                  hintText: 'Name or code',
                ),
                onChanged: (value) => setState(() => _search = value),
              ),
            ),
            SizedBox(
              width: Responsive.controlWidth(context, preferred: 260),
              child: DropdownButtonFormField<String?>(
                initialValue: _selectedClassId,
                decoration: const InputDecoration(labelText: 'Filter by Class'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Classes'),
                  ),
                  ...classes.map(
                    (c) => DropdownMenuItem<String?>(
                      value: c.id,
                      child: Text(c.name),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _selectedClassId = value),
              ),
            ),
            FilledButton.icon(
              onPressed: _openAddSubjectDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Subject'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final filtered = _filteredSubjects;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _StatChip(
              label: 'Total Subjects',
              value: _controller.subjects.length.toString(),
              color: Colors.blue,
            ),
            _StatChip(
              label: 'Visible',
              value: filtered.length.toString(),
              color: Colors.teal,
            ),
            _StatChip(
              label: 'Teachers',
              value: _controller.teachers.length.toString(),
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectsList() {
    final filtered = _filteredSubjects;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subject Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (filtered.isEmpty)
              const Text('No subjects found for current filters.')
            else
              ...filtered.map(
                (item) => ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.book_rounded)),
                  title: Text(item.name),
                  subtitle: Text(
                    '${item.code} | ${_teacherName(item.teacherId)} | ${_className(item.classId)}',
                  ),
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () => _openEditSubjectDialog(item),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () => _controller.deleteSubject(item.id),
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

  List<SubjectItem> get _filteredSubjects {
    final q = _search.trim().toLowerCase();
    return _controller.subjects.where((item) {
        if (_selectedClassId != null && item.classId != _selectedClassId) {
          return false;
        }
        if (q.isEmpty) return true;
        return item.name.toLowerCase().contains(q) ||
            item.code.toLowerCase().contains(q);
      }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<void> _openAddSubjectDialog() async {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    String? teacherId;
    String? classId;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          actionsOverflowDirection: VerticalDirection.down,
          actionsOverflowButtonSpacing: 8,
          title: const Text('Add Subject'),
          content: _responsiveDialogContent(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Subject Name'),
                ),
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Subject Code'),
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
                if (nameController.text.trim().isEmpty ||
                    codeController.text.trim().isEmpty ||
                    teacherId == null ||
                    classId == null) {
                  _showError('Fill all subject fields.');
                  return;
                }
                _controller.addSubject(
                  name: nameController.text.trim(),
                  code: codeController.text.trim(),
                  teacherId: teacherId!,
                  classId: classId!,
                );
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    Future<void>.delayed(const Duration(milliseconds: 200), () {
      nameController.dispose();
      codeController.dispose();
    });
  }

  Future<void> _openEditSubjectDialog(SubjectItem existing) async {
    final nameController = TextEditingController(text: existing.name);
    final codeController = TextEditingController(text: existing.code);
    String? teacherId = existing.teacherId;
    String? classId = existing.classId;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          actionsOverflowDirection: VerticalDirection.down,
          actionsOverflowButtonSpacing: 8,
          title: const Text('Edit Subject'),
          content: _responsiveDialogContent(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Subject Name'),
                ),
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Subject Code'),
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
                if (nameController.text.trim().isEmpty ||
                    codeController.text.trim().isEmpty ||
                    teacherId == null ||
                    classId == null) {
                  _showError('Fill all subject fields.');
                  return;
                }
                _controller.updateSubject(
                  id: existing.id,
                  name: nameController.text.trim(),
                  code: codeController.text.trim(),
                  teacherId: teacherId!,
                  classId: classId!,
                );
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    Future<void>.delayed(const Duration(milliseconds: 200), () {
      nameController.dispose();
      codeController.dispose();
    });
  }

  void _retrySync() {
    final uid = _auth.user?.uid;
    if (uid == null) return;
    _controller.retrySync(uid);
  }

  String _teacherName(String teacherId) {
    final teacher = _controller.teachers
        .where((e) => e.id == teacherId)
        .firstOrNull;
    return teacher?.name ?? 'Teacher';
  }

  String _className(String classId) {
    final schoolClass = _controller.classes
        .where((e) => e.id == classId)
        .firstOrNull;
    return schoolClass?.name ?? 'Class';
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }
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
