import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/module_ai_action_button.dart';
import '../../../../core/widgets/session_menu_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/exam_item.dart';
import '../controllers/exams_controller.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  final ExamsController _controller = Get.find<ExamsController>();
  final AuthProvider _auth = Get.find<AuthProvider>();
  final ThemeProvider _theme = Get.find<ThemeProvider>();

  String? _boundUid;
  String _search = '';
  ExamTargetType? _targetFilter;

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
    if (Get.isRegistered<ExamsController>()) {
      Get.delete<ExamsController>();
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
        title: const Text('Exams'),
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
          const ModuleAiActionButton(moduleName: 'Exams'),
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
                              ? 'Local mode: exams not synced to cloud.'
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
                        _buildExamsList(),
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
                  labelText: 'Search Exams',
                  hintText: 'Title or subject',
                ),
                onChanged: (value) => setState(() => _search = value),
              ),
            ),
            SizedBox(
              width: Responsive.controlWidth(context, preferred: 240),
              child: DropdownButtonFormField<ExamTargetType?>(
                initialValue: _targetFilter,
                decoration: const InputDecoration(
                  labelText: 'Filter by Target',
                ),
                items: const [
                  DropdownMenuItem<ExamTargetType?>(
                    value: null,
                    child: Text('All Targets'),
                  ),
                  DropdownMenuItem<ExamTargetType?>(
                    value: ExamTargetType.student,
                    child: Text('Students'),
                  ),
                  DropdownMenuItem<ExamTargetType?>(
                    value: ExamTargetType.teacher,
                    child: Text('Teachers'),
                  ),
                  DropdownMenuItem<ExamTargetType?>(
                    value: ExamTargetType.schoolClass,
                    child: Text('Classes'),
                  ),
                ],
                onChanged: (value) => setState(() => _targetFilter = value),
              ),
            ),
            FilledButton.icon(
              onPressed: _openAddExamDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Exam'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final filtered = _filteredExams;
    final exams = _controller.exams;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _StatChip(
              label: 'Total Exams',
              value: exams.length.toString(),
              color: Colors.blue,
            ),
            _StatChip(
              label: 'Visible',
              value: filtered.length.toString(),
              color: Colors.teal,
            ),
            _StatChip(
              label: 'Students',
              value: exams
                  .where((e) => e.targetType == ExamTargetType.student)
                  .length
                  .toString(),
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamsList() {
    final filtered = _filteredExams;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exam Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (filtered.isEmpty)
              const Text('No exams found for current filters.')
            else
              ...filtered.map(
                (item) => ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.assignment_rounded),
                  ),
                  title: Text(item.title),
                  subtitle: Text(
                    '${item.date} | ${item.subject} | ${_targetTitle(item.targetType, item.targetId)}',
                  ),
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () => _openEditExamDialog(item),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () => _controller.deleteExam(item.id),
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

  List<ExamItem> get _filteredExams {
    final q = _search.trim().toLowerCase();
    return _controller.exams.where((item) {
      if (_targetFilter != null && item.targetType != _targetFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      return item.title.toLowerCase().contains(q) ||
          item.subject.toLowerCase().contains(q);
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> _openAddExamDialog() async {
    final titleController = TextEditingController();
    final subjectController = TextEditingController();
    final dateController = TextEditingController();
    ExamTargetType targetType = ExamTargetType.student;
    String? targetId;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          actionsOverflowDirection: VerticalDirection.down,
          actionsOverflowButtonSpacing: 8,
          title: const Text('Add Exam'),
          content: _responsiveDialogContent(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Exam Title'),
                ),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(labelText: 'Date'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ExamTargetType>(
                  initialValue: targetType,
                  decoration: const InputDecoration(labelText: 'Target Type'),
                  items: const [
                    DropdownMenuItem(
                      value: ExamTargetType.student,
                      child: Text('Student'),
                    ),
                    DropdownMenuItem(
                      value: ExamTargetType.teacher,
                      child: Text('Teacher'),
                    ),
                    DropdownMenuItem(
                      value: ExamTargetType.schoolClass,
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
                        (e) => DropdownMenuItem<String>(
                          value: e.id,
                          child: Text(e.label),
                        ),
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
                    subjectController.text.trim().isEmpty ||
                    dateController.text.trim().isEmpty ||
                    targetId == null) {
                  _showError('Fill all exam fields.');
                  return;
                }
                _controller.addExam(
                  title: titleController.text.trim(),
                  subject: subjectController.text.trim(),
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

    Future<void>.delayed(const Duration(milliseconds: 200), () {
      titleController.dispose();
      subjectController.dispose();
      dateController.dispose();
    });
  }

  Future<void> _openEditExamDialog(ExamItem existing) async {
    final titleController = TextEditingController(text: existing.title);
    final subjectController = TextEditingController(text: existing.subject);
    final dateController = TextEditingController(text: existing.date);
    ExamTargetType targetType = existing.targetType;
    String? targetId = existing.targetId;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          actionsOverflowDirection: VerticalDirection.down,
          actionsOverflowButtonSpacing: 8,
          title: const Text('Edit Exam'),
          content: _responsiveDialogContent(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Exam Title'),
                ),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(labelText: 'Date'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ExamTargetType>(
                  initialValue: targetType,
                  decoration: const InputDecoration(labelText: 'Target Type'),
                  items: const [
                    DropdownMenuItem(
                      value: ExamTargetType.student,
                      child: Text('Student'),
                    ),
                    DropdownMenuItem(
                      value: ExamTargetType.teacher,
                      child: Text('Teacher'),
                    ),
                    DropdownMenuItem(
                      value: ExamTargetType.schoolClass,
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
                        (e) => DropdownMenuItem<String>(
                          value: e.id,
                          child: Text(e.label),
                        ),
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
                    subjectController.text.trim().isEmpty ||
                    dateController.text.trim().isEmpty ||
                    targetId == null) {
                  _showError('Fill all exam fields.');
                  return;
                }
                _controller.updateExam(
                  id: existing.id,
                  title: titleController.text.trim(),
                  subject: subjectController.text.trim(),
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

    Future<void>.delayed(const Duration(milliseconds: 200), () {
      titleController.dispose();
      subjectController.dispose();
      dateController.dispose();
    });
  }

  List<_EntityOption> _targetOptions(ExamTargetType type) {
    switch (type) {
      case ExamTargetType.student:
        return _controller.students
            .map((e) => _EntityOption(id: e.id, label: 'Student: ${e.name}'))
            .toList();
      case ExamTargetType.teacher:
        return _controller.teachers
            .map((e) => _EntityOption(id: e.id, label: 'Teacher: ${e.name}'))
            .toList();
      case ExamTargetType.schoolClass:
        return _controller.classes
            .map((e) => _EntityOption(id: e.id, label: 'Class: ${e.name}'))
            .toList();
    }
  }

  String _targetTitle(ExamTargetType type, String id) {
    switch (type) {
      case ExamTargetType.student:
        final student = _controller.students
            .where((e) => e.id == id)
            .firstOrNull;
        return student == null ? 'Student' : 'Student: ${student.name}';
      case ExamTargetType.teacher:
        final teacher = _controller.teachers
            .where((e) => e.id == id)
            .firstOrNull;
        return teacher == null ? 'Teacher' : 'Teacher: ${teacher.name}';
      case ExamTargetType.schoolClass:
        final schoolClass = _controller.classes
            .where((e) => e.id == id)
            .firstOrNull;
        return schoolClass == null ? 'Class' : 'Class: ${schoolClass.name}';
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
