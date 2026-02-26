import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/module_ai_action_button.dart';
import '../../../../core/widgets/session_menu_button.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../dashboard/data/services/school_management_service.dart';
import '../../data/models/result_item.dart';
import '../controllers/results_controller.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final ResultsController _controller = Get.find<ResultsController>();
  final AuthProvider _auth = Get.find<AuthProvider>();
  final ThemeProvider _theme = Get.find<ThemeProvider>();

  String? _boundUid;
  AppRole _role = AppRole.admin;
  List<String> _linkedStudentIds = const [];
  String? _currentUserEmail;
  String? _mappedTeacherId;
  String _search = '';
  String? _selectedClassId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = _auth.user?.uid;
    final user = _auth.user;
    _role = user?.role ?? AppRole.admin;
    _linkedStudentIds = user?.linkedStudentIds ?? const [];
    _currentUserEmail = user?.email;
    _mappedTeacherId = user?.teacherId;
    if (uid == null || uid == _boundUid) return;
    _boundUid = uid;
    _controller.bind(uid);
  }

  @override
  void dispose() {
    if (Get.isRegistered<ResultsController>()) {
      Get.delete<ResultsController>();
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
        title: const Text('Results'),
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
          const ModuleAiActionButton(moduleName: 'Results'),
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
                              ? 'Local mode: results not synced to cloud.'
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
                        _buildResultsList(),
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
    final allowedClassIds = _allowedClassIds;
    final roleClasses = _controller.classes
        .where((c) => allowedClassIds.contains(c.id))
        .toList();
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
                  labelText: 'Search Results',
                  hintText: 'Student, subject or exam',
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
                  ...roleClasses.map(
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
              onPressed: _openAddResultDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Result'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final filtered = _filteredResults;
    final avg = filtered.isEmpty
        ? 0
        : filtered.map((e) => e.score).reduce((a, b) => a + b) /
              filtered.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _StatChip(
              label: 'Total Results',
              value: _controller.results.length.toString(),
              color: Colors.blue,
            ),
            _StatChip(
              label: 'Visible',
              value: filtered.length.toString(),
              color: Colors.teal,
            ),
            _StatChip(
              label: 'Average Score',
              value: avg.toStringAsFixed(1),
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    final filtered = _filteredResults;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Result Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (filtered.isEmpty)
              const Text('No results found for current filters.')
            else
              ...filtered.map(
                (item) => ListTile(
                  leading: CircleAvatar(child: Text(item.grade)),
                  title: Text(
                    '${_studentName(item.studentId)} • ${item.subject}',
                  ),
                  subtitle: Text(
                    '${item.examTitle} | Score ${item.score.toStringAsFixed(1)} | ${_className(item.classId)}',
                  ),
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () => _openEditResultDialog(item),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () => _controller.deleteResult(item.id),
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

  List<ResultItem> get _filteredResults {
    final allowedClasses = _allowedClassIds;
    final linkedIds = _linkedStudentIds.toSet();
    final q = _search.trim().toLowerCase();
    return _controller.results.where((item) {
      if (_role == AppRole.teacher && !allowedClasses.contains(item.classId)) {
        return false;
      }
      if ((_role == AppRole.parent || _role == AppRole.student) &&
          !linkedIds.contains(item.studentId)) {
        return false;
      }
      if (_selectedClassId != null && item.classId != _selectedClassId) {
        return false;
      }
      if (q.isEmpty) return true;
      final student = _studentName(item.studentId).toLowerCase();
      return student.contains(q) ||
          item.subject.toLowerCase().contains(q) ||
          item.examTitle.toLowerCase().contains(q);
    }).toList()..sort((a, b) => b.score.compareTo(a.score));
  }

  Future<void> _openAddResultDialog() async {
    final examController = TextEditingController();
    final subjectController = TextEditingController();
    final scoreController = TextEditingController();
    String? classId;
    String? studentId;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          actionsOverflowDirection: VerticalDirection.down,
          actionsOverflowButtonSpacing: 8,
          title: const Text('Add Result'),
          content: _responsiveDialogContent(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: examController,
                  decoration: const InputDecoration(labelText: 'Exam Title'),
                ),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                TextField(
                  controller: scoreController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Score'),
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
                  onChanged: (v) {
                    setDialog(() {
                      classId = v;
                      studentId = null;
                    });
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: studentId,
                  decoration: const InputDecoration(labelText: 'Student'),
                  items: _studentsForClass(classId)
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.id,
                          child: Text('${e.name} (${e.rollNumber})'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialog(() => studentId = v),
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
                final score = double.tryParse(scoreController.text.trim());
                if (examController.text.trim().isEmpty ||
                    subjectController.text.trim().isEmpty ||
                    classId == null ||
                    studentId == null ||
                    score == null) {
                  _showError('Fill all result fields.');
                  return;
                }
                _controller.addResult(
                  ResultItem(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    examTitle: examController.text.trim(),
                    subject: subjectController.text.trim(),
                    score: score,
                    grade: _gradeFromScore(score),
                    classId: classId!,
                    studentId: studentId!,
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

  Future<void> _openEditResultDialog(ResultItem existing) async {
    final examController = TextEditingController(text: existing.examTitle);
    final subjectController = TextEditingController(text: existing.subject);
    final scoreController = TextEditingController(
      text: existing.score.toString(),
    );
    String? classId = existing.classId;
    String? studentId = existing.studentId;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          actionsOverflowDirection: VerticalDirection.down,
          actionsOverflowButtonSpacing: 8,
          title: const Text('Edit Result'),
          content: _responsiveDialogContent(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: examController,
                  decoration: const InputDecoration(labelText: 'Exam Title'),
                ),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                TextField(
                  controller: scoreController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Score'),
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
                  onChanged: (v) {
                    setDialog(() {
                      classId = v;
                      studentId = null;
                    });
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: studentId,
                  decoration: const InputDecoration(labelText: 'Student'),
                  items: _studentsForClass(classId)
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.id,
                          child: Text('${e.name} (${e.rollNumber})'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialog(() => studentId = v),
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
                final score = double.tryParse(scoreController.text.trim());
                if (examController.text.trim().isEmpty ||
                    subjectController.text.trim().isEmpty ||
                    classId == null ||
                    studentId == null ||
                    score == null) {
                  _showError('Fill all result fields.');
                  return;
                }
                _controller.updateResult(
                  ResultItem(
                    id: existing.id,
                    examTitle: examController.text.trim(),
                    subject: subjectController.text.trim(),
                    score: score,
                    grade: _gradeFromScore(score),
                    classId: classId!,
                    studentId: studentId!,
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

  List<SchoolStudent> _studentsForClass(String? classId) {
    if (classId == null) return const [];
    final schoolClass = _controller.classes
        .where((e) => e.id == classId)
        .firstOrNull;
    if (schoolClass == null) return const [];
    return schoolClass.studentIds
        .map((id) => _controller.students.where((s) => s.id == id).firstOrNull)
        .whereType<SchoolStudent>()
        .toList();
  }

  String _studentName(String studentId) {
    final student = _controller.students
        .where((e) => e.id == studentId)
        .firstOrNull;
    return student?.name ?? 'Student';
  }

  String _className(String classId) {
    final schoolClass = _controller.classes
        .where((e) => e.id == classId)
        .firstOrNull;
    return schoolClass?.name ?? 'Class';
  }

  String _gradeFromScore(double score) {
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  Set<String> get _allowedClassIds {
    final classes = _controller.classes;
    if (_role == AppRole.admin) {
      return classes.map((e) => e.id).toSet();
    }
    if (_role == AppRole.teacher) {
      if (_mappedTeacherId != null && _mappedTeacherId!.isNotEmpty) {
        return classes
            .where(
              (c) => c.teacherId != null && c.teacherId == _mappedTeacherId,
            )
            .map((c) => c.id)
            .toSet();
      }
      final teacherIds = _controller.teachers
          .where(
            (t) =>
                _currentUserEmail != null &&
                t.email.toLowerCase() == _currentUserEmail!.toLowerCase(),
          )
          .map((e) => e.id)
          .toSet();
      return classes
          .where((c) => c.teacherId != null && teacherIds.contains(c.teacherId))
          .map((c) => c.id)
          .toSet();
    }
    final linked = _linkedStudentIds.toSet();
    return classes
        .where((c) => c.studentIds.any(linked.contains))
        .map((c) => c.id)
        .toSet();
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
