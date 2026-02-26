import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/module_ai_action_button.dart';
import '../../../../core/widgets/session_menu_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/library_item.dart';
import '../controllers/library_controller.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final LibraryController _controller = Get.find<LibraryController>();
  final AuthProvider _auth = Get.find<AuthProvider>();
  final ThemeProvider _theme = Get.find<ThemeProvider>();

  String? _boundUid;
  String _search = '';
  bool? _returnedFilter;

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
    if (Get.isRegistered<LibraryController>()) {
      Get.delete<LibraryController>();
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
        title: const Text('Library'),
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
          const ModuleAiActionButton(moduleName: 'Library'),
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
                              ? 'Local mode: library not synced to cloud.'
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
                        _buildLibraryList(),
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
                  labelText: 'Search Books',
                  hintText: 'Book name',
                ),
                onChanged: (value) => setState(() => _search = value),
              ),
            ),
            SizedBox(
              width: Responsive.controlWidth(context, preferred: 240),
              child: DropdownButtonFormField<bool?>(
                initialValue: _returnedFilter,
                decoration: const InputDecoration(labelText: 'Return Status'),
                items: const [
                  DropdownMenuItem<bool?>(value: null, child: Text('All')),
                  DropdownMenuItem<bool?>(value: true, child: Text('Returned')),
                  DropdownMenuItem<bool?>(
                    value: false,
                    child: Text('Not Returned'),
                  ),
                ],
                onChanged: (value) => setState(() => _returnedFilter = value),
              ),
            ),
            FilledButton.icon(
              onPressed: _openAddLibraryDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Issue Book'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final filtered = _filteredItems;
    final returned = _controller.items.where((e) => e.returned).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _StatChip(
              label: 'Total Books',
              value: _controller.items.length.toString(),
              color: Colors.blue,
            ),
            _StatChip(
              label: 'Returned',
              value: returned.toString(),
              color: Colors.green,
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

  Widget _buildLibraryList() {
    final filtered = _filteredItems;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Library Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (filtered.isEmpty)
              const Text('No library records found for current filters.')
            else
              ...filtered.map(
                (item) => ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      item.returned
                          ? Icons.assignment_returned_rounded
                          : Icons.menu_book_rounded,
                    ),
                  ),
                  title: Text(item.bookName),
                  subtitle: Text(
                    'Due ${item.dueDate} | ${_targetTitle(item.targetType, item.targetId)}',
                  ),
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      IconButton(
                        tooltip: item.returned
                            ? 'Mark Not Returned'
                            : 'Mark Returned',
                        onPressed: () => _controller.toggleReturned(item.id),
                        icon: Icon(
                          item.returned
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () => _openEditLibraryDialog(item),
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

  List<LibraryItem> get _filteredItems {
    final q = _search.trim().toLowerCase();
    return _controller.items.where((item) {
      if (_returnedFilter != null && item.returned != _returnedFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      return item.bookName.toLowerCase().contains(q);
    }).toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  Future<void> _openAddLibraryDialog() async {
    final bookController = TextEditingController();
    final dueController = TextEditingController();
    LibraryTargetType targetType = LibraryTargetType.student;
    String? targetId;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          actionsOverflowDirection: VerticalDirection.down,
          actionsOverflowButtonSpacing: 8,
          title: const Text('Issue Book'),
          content: _responsiveDialogContent(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: bookController,
                  decoration: const InputDecoration(labelText: 'Book Name'),
                ),
                TextField(
                  controller: dueController,
                  decoration: const InputDecoration(labelText: 'Due Date'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<LibraryTargetType>(
                  initialValue: targetType,
                  decoration: const InputDecoration(labelText: 'Target Type'),
                  items: const [
                    DropdownMenuItem(
                      value: LibraryTargetType.student,
                      child: Text('Student'),
                    ),
                    DropdownMenuItem(
                      value: LibraryTargetType.teacher,
                      child: Text('Teacher'),
                    ),
                    DropdownMenuItem(
                      value: LibraryTargetType.schoolClass,
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
                if (bookController.text.trim().isEmpty ||
                    dueController.text.trim().isEmpty ||
                    targetId == null) {
                  _showError('Fill all library fields.');
                  return;
                }
                _controller.addItem(
                  bookName: bookController.text.trim(),
                  dueDate: dueController.text.trim(),
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
      bookController.dispose();
      dueController.dispose();
    });
  }

  Future<void> _openEditLibraryDialog(LibraryItem existing) async {
    final bookController = TextEditingController(text: existing.bookName);
    final dueController = TextEditingController(text: existing.dueDate);
    LibraryTargetType targetType = existing.targetType;
    String? targetId = existing.targetId;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          actionsOverflowDirection: VerticalDirection.down,
          actionsOverflowButtonSpacing: 8,
          title: const Text('Edit Library Item'),
          content: _responsiveDialogContent(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: bookController,
                  decoration: const InputDecoration(labelText: 'Book Name'),
                ),
                TextField(
                  controller: dueController,
                  decoration: const InputDecoration(labelText: 'Due Date'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<LibraryTargetType>(
                  initialValue: targetType,
                  decoration: const InputDecoration(labelText: 'Target Type'),
                  items: const [
                    DropdownMenuItem(
                      value: LibraryTargetType.student,
                      child: Text('Student'),
                    ),
                    DropdownMenuItem(
                      value: LibraryTargetType.teacher,
                      child: Text('Teacher'),
                    ),
                    DropdownMenuItem(
                      value: LibraryTargetType.schoolClass,
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
                if (bookController.text.trim().isEmpty ||
                    dueController.text.trim().isEmpty ||
                    targetId == null) {
                  _showError('Fill all library fields.');
                  return;
                }
                _controller.updateItem(
                  id: existing.id,
                  bookName: bookController.text.trim(),
                  dueDate: dueController.text.trim(),
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
      bookController.dispose();
      dueController.dispose();
    });
  }

  List<_EntityOption> _targetOptions(LibraryTargetType type) {
    switch (type) {
      case LibraryTargetType.student:
        return _controller.students
            .map((e) => _EntityOption(id: e.id, label: 'Student: ${e.name}'))
            .toList();
      case LibraryTargetType.teacher:
        return _controller.teachers
            .map((e) => _EntityOption(id: e.id, label: 'Teacher: ${e.name}'))
            .toList();
      case LibraryTargetType.schoolClass:
        return _controller.classes
            .map((e) => _EntityOption(id: e.id, label: 'Class: ${e.name}'))
            .toList();
    }
  }

  String _targetTitle(LibraryTargetType type, String id) {
    switch (type) {
      case LibraryTargetType.student:
        final student = _controller.students
            .where((e) => e.id == id)
            .firstOrNull;
        return student == null ? 'Student' : 'Student: ${student.name}';
      case LibraryTargetType.teacher:
        final teacher = _controller.teachers
            .where((e) => e.id == id)
            .firstOrNull;
        return teacher == null ? 'Teacher' : 'Teacher: ${teacher.name}';
      case LibraryTargetType.schoolClass:
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
