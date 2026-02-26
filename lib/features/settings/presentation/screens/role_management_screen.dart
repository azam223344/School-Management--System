import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/session_menu_button.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../dashboard/data/services/school_management_service.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  final AuthProvider _auth = Get.find<AuthProvider>();
  final SchoolManagementService _service = SchoolManagementService();

  StreamSubscription<List<UserAccessProfile>>? _usersSub;
  StreamSubscription<List<SchoolStudent>>? _studentsSub;
  StreamSubscription<List<SchoolTeacher>>? _teachersSub;

  List<UserAccessProfile> _users = const [];
  List<SchoolStudent> _students = const [];
  List<SchoolTeacher> _teachers = const [];

  bool _isLoading = true;
  bool _isBusy = false;
  String _search = '';
  String? _uid;
  final Set<String> _selectedUserIds = <String>{};
  AppRole? _bulkRole;
  AppRole? _roleFilter;
  bool _showOnlyIssues = false;

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onAuthChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = _auth.user?.uid;
    if (uid == null || uid == _uid) return;
    _uid = uid;
    _bind(uid);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _usersSub?.cancel();
    _studentsSub?.cancel();
    _teachersSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: const Text('Role Management'),
          actions: const [SessionMenuButton(showHome: true)],
        ),
        body: const Center(child: Text('Only admins can access this screen.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Role Management'),
        actions: const [SessionMenuButton(showHome: true)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.all(Responsive.pagePadding(context)),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: Responsive.contentMaxWidth(
                          context,
                          desktop: 1100,
                          tablet: 900,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSummaryCard(),
                          const SizedBox(height: 12),
                          _buildFilterCard(),
                          const SizedBox(height: 12),
                          if (_selectedUserIds.isNotEmpty) ...[
                            _buildBulkActionsCard(),
                            const SizedBox(height: 12),
                          ],
                          if (_filteredUsers.isNotEmpty)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _selectAllFiltered,
                                    icon: const Icon(Icons.select_all_rounded),
                                    label: const Text('Select Visible'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: _selectIssueUsersFiltered,
                                    icon: const Icon(
                                      Icons.warning_amber_rounded,
                                    ),
                                    label: const Text('Select Issues'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: _selectedUserIds.isEmpty
                                        ? null
                                        : () => setState(
                                            () => _selectedUserIds.clear(),
                                          ),
                                    icon: const Icon(Icons.deselect_rounded),
                                    label: const Text('Clear Selection'),
                                  ),
                                ],
                              ),
                            ),
                          if (_filteredUsers.isNotEmpty)
                            const SizedBox(height: 12),
                          if (_filteredUsers.isEmpty)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Text(
                                  'No users found for current filters.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ),
                          ..._filteredUsers.map(_buildUserCard),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_isBusy)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x66000000),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildSummaryCard() {
    final total = _users.length;
    final admins = _users.where((u) => u.role == AppRole.admin).length;
    final teachers = _users.where((u) => u.role == AppRole.teacher).length;
    final parents = _users.where((u) => u.role == AppRole.parent).length;
    final students = _users.where((u) => u.role == AppRole.student).length;
    final issues = _users.where((u) => _auditIssues(u).isNotEmpty).length;
    final teacherProfileIssues = _users
        .where(
          (u) =>
              u.role == AppRole.teacher &&
              (u.teacherId == null || u.teacherId!.isEmpty),
        )
        .length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatChip(label: 'Users', value: '$total', color: Colors.blue),
                _StatChip(
                  label: 'Admins',
                  value: '$admins',
                  color: Colors.indigo,
                ),
                _StatChip(
                  label: 'Teachers',
                  value: '$teachers',
                  color: Colors.green,
                ),
                _StatChip(
                  label: 'Parents',
                  value: '$parents',
                  color: Colors.orange,
                ),
                _StatChip(
                  label: 'Students',
                  value: '$students',
                  color: Colors.purple,
                ),
                _StatChip(
                  label: 'Audit Issues',
                  value: '$issues',
                  color: Colors.red,
                ),
              ],
            ),
            if (teacherProfileIssues > 0) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _resolveTeacherProfileIssues,
                icon: const Icon(Icons.auto_fix_high_rounded),
                label: Text('Fix Teacher Profiles ($teacherProfileIssues)'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: Responsive.controlWidth(context, preferred: 320),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  labelText: 'Search users',
                  hintText: 'Name or email',
                ),
                onChanged: (value) => setState(() => _search = value),
              ),
            ),
            SizedBox(
              width: Responsive.controlWidth(context, preferred: 220),
              child: DropdownButtonFormField<AppRole?>(
                initialValue: _roleFilter,
                decoration: const InputDecoration(labelText: 'Role Filter'),
                items: [
                  const DropdownMenuItem<AppRole?>(
                    value: null,
                    child: Text('All Roles'),
                  ),
                  ...AppRole.values.map(
                    (role) => DropdownMenuItem(
                      value: role,
                      child: Text(_roleLabel(role)),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _roleFilter = value),
              ),
            ),
            FilterChip(
              label: const Text('Only Issues'),
              selected: _showOnlyIssues,
              onSelected: (value) => setState(() => _showOnlyIssues = value),
            ),
            OutlinedButton.icon(
              onPressed: _exportFilteredUsersCsv,
              icon: const Icon(Icons.download_rounded),
              label: const Text('Export CSV'),
            ),
            OutlinedButton.icon(
              onPressed: _openImportCsvDialog,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Import CSV'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bulk Actions (${_selectedUserIds.length} selected)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: Responsive.controlWidth(context, preferred: 220),
                  child: DropdownButtonFormField<AppRole?>(
                    initialValue: _bulkRole,
                    decoration: const InputDecoration(labelText: 'Assign Role'),
                    items: [
                      const DropdownMenuItem<AppRole?>(
                        value: null,
                        child: Text('Select role'),
                      ),
                      ...AppRole.values.map(
                        (role) => DropdownMenuItem(
                          value: role,
                          child: Text(_roleLabel(role)),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _bulkRole = value),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _bulkRole == null ? null : _applyBulkRole,
                  icon: const Icon(Icons.done_all_rounded),
                  label: const Text('Apply Role'),
                ),
                OutlinedButton.icon(
                  onPressed: _clearLinkedStudentsForSelection,
                  icon: const Icon(Icons.link_off_rounded),
                  label: const Text('Clear Links'),
                ),
                OutlinedButton.icon(
                  onPressed: _clearTeacherMappingForSelection,
                  icon: const Icon(Icons.person_off_rounded),
                  label: const Text('Clear Teacher Map'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<UserAccessProfile> get _filteredUsers {
    final q = _search.trim().toLowerCase();
    return _users.where((u) {
      final matchesSearch =
          q.isEmpty ||
          u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
      final matchesRole = _roleFilter == null || u.role == _roleFilter;
      final matchesIssue = !_showOnlyIssues || _auditIssues(u).isNotEmpty;
      return matchesSearch && matchesRole && matchesIssue;
    }).toList();
  }

  Widget _buildUserCard(UserAccessProfile user) {
    final auditIssues = _auditIssues(user);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _selectedUserIds.contains(user.uid),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedUserIds.add(user.uid);
                      } else {
                        _selectedUserIds.remove(user.uid);
                      }
                    });
                  },
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name.isEmpty ? '(No Name)' : user.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _RoleBadge(role: user.role),
                          if (user.role == AppRole.parent ||
                              user.role == AppRole.student)
                            _TinyInfo(
                              label: 'Linked: ${user.linkedStudentIds.length}',
                            ),
                          if (user.role == AppRole.teacher)
                            _TinyInfo(
                              label: user.teacherId == null
                                  ? 'Teacher Map: none'
                                  : 'Teacher Map: set',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(user.email.isEmpty ? 'No email' : user.email),
            if (auditIssues.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: auditIssues
                    .map(
                      (issue) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Colors.red.withValues(alpha: 0.14),
                        ),
                        child: Text(
                          issue,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: Responsive.controlWidth(context, preferred: 220),
                  child: DropdownButtonFormField<AppRole>(
                    initialValue: user.role,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: AppRole.values
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(_roleLabel(r)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) async {
                      if (value == null) return;
                      await _runAction(
                        message: 'Role updated for ${_userLabel(user)}',
                        action: () => _service.updateUserAccess(
                          uid: user.uid,
                          role: value,
                          linkedStudentIds:
                              value == AppRole.parent ||
                                  value == AppRole.student
                              ? user.linkedStudentIds
                              : const [],
                          teacherId: value == AppRole.teacher
                              ? user.teacherId
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                if (user.role == AppRole.teacher)
                  SizedBox(
                    width: Responsive.controlWidth(context, preferred: 320),
                    child: DropdownButtonFormField<String?>(
                      initialValue: user.teacherId,
                      decoration: const InputDecoration(
                        labelText: 'Teacher Profile',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Unassigned'),
                        ),
                        ..._teachers.map(
                          (t) => DropdownMenuItem<String?>(
                            value: t.id,
                            child: Text('${t.name} (${t.subject})'),
                          ),
                        ),
                      ],
                      onChanged: (value) async {
                        await _runAction(
                          message:
                              'Teacher mapping updated for ${_userLabel(user)}',
                          action: () => _service.updateUserAccess(
                            uid: user.uid,
                            role: user.role,
                            linkedStudentIds: user.linkedStudentIds,
                            teacherId: value,
                          ),
                        );
                      },
                    ),
                  ),
                if (user.role == AppRole.parent || user.role == AppRole.student)
                  OutlinedButton.icon(
                    onPressed: () => _pickLinkedStudents(user),
                    icon: const Icon(Icons.link_rounded),
                    label: Text(
                      user.linkedStudentIds.isEmpty
                          ? 'Link Students'
                          : '${user.linkedStudentIds.length} linked',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLinkedStudents(UserAccessProfile user) async {
    final selected = user.linkedStudentIds.toSet();
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          actionsOverflowDirection: VerticalDirection.down,
          actionsOverflowButtonSpacing: 8,
          title: const Text('Link Students'),
          content: SizedBox(
            width: Responsive.controlWidth(context, preferred: 420),
            child: SingleChildScrollView(
              child: Column(
                children: _students.map((s) {
                  final checked = selected.contains(s.id);
                  return CheckboxListTile(
                    value: checked,
                    title: Text(s.name),
                    subtitle: Text('${s.rollNumber} • ${s.grade}'),
                    onChanged: (value) {
                      setDialog(() {
                        if (value == true) {
                          selected.add(s.id);
                        } else {
                          selected.remove(s.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, selected),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;
    await _runAction(
      message: 'Linked students updated for ${_userLabel(user)}',
      action: () => _service.updateUserAccess(
        uid: user.uid,
        role: user.role,
        linkedStudentIds: result.toList(),
        teacherId: user.teacherId,
      ),
    );
  }

  String _roleLabel(AppRole role) {
    switch (role) {
      case AppRole.admin:
        return 'Admin';
      case AppRole.teacher:
        return 'Teacher';
      case AppRole.parent:
        return 'Parent';
      case AppRole.student:
        return 'Student';
    }
  }

  List<String> _auditIssues(UserAccessProfile user) {
    final issues = <String>[];
    if (user.role == AppRole.teacher &&
        (user.teacherId == null || user.teacherId!.isEmpty)) {
      issues.add('Teacher profile missing');
    }
    if ((user.role == AppRole.parent || user.role == AppRole.student) &&
        user.linkedStudentIds.isEmpty) {
      issues.add('Linked student missing');
    }
    return issues;
  }

  void _selectAllFiltered() {
    setState(() {
      _selectedUserIds
        ..clear()
        ..addAll(_filteredUsers.map((u) => u.uid));
    });
  }

  void _selectIssueUsersFiltered() {
    setState(() {
      _selectedUserIds
        ..clear()
        ..addAll(
          _filteredUsers
              .where((u) => _auditIssues(u).isNotEmpty)
              .map((u) => u.uid),
        );
    });
  }

  Future<void> _applyBulkRole() async {
    final role = _bulkRole;
    if (role == null || _selectedUserIds.isEmpty) return;
    final selectedUsers = _users
        .where((u) => _selectedUserIds.contains(u.uid))
        .toList();
    final undoSnapshots = _snapshotsFromUsers(selectedUsers);
    await _runAction(
      message: 'Role updated for ${_selectedUserIds.length} users',
      undoSnapshots: undoSnapshots,
      action: () => Future.wait(
        selectedUsers.map((user) {
          return _service.updateUserAccess(
            uid: user.uid,
            role: role,
            linkedStudentIds: role == AppRole.parent || role == AppRole.student
                ? user.linkedStudentIds
                : const [],
            teacherId: role == AppRole.teacher ? user.teacherId : null,
          );
        }),
      ),
    );
  }

  Future<void> _clearLinkedStudentsForSelection() async {
    if (_selectedUserIds.isEmpty) return;
    final confirm = await _confirmAction(
      title: 'Clear linked students?',
      content:
          'This will remove linked students for all selected users. Continue?',
    );
    if (confirm != true) return;
    final selectedUsers = _users
        .where((u) => _selectedUserIds.contains(u.uid))
        .toList();
    final undoSnapshots = _snapshotsFromUsers(selectedUsers);
    await _runAction(
      message: 'Cleared linked students for ${_selectedUserIds.length} users',
      undoSnapshots: undoSnapshots,
      action: () => Future.wait(
        selectedUsers.map((user) {
          return _service.updateUserAccess(
            uid: user.uid,
            role: user.role,
            linkedStudentIds: const [],
            teacherId: user.teacherId,
          );
        }),
      ),
    );
  }

  Future<void> _clearTeacherMappingForSelection() async {
    if (_selectedUserIds.isEmpty) return;
    final confirm = await _confirmAction(
      title: 'Clear teacher mapping?',
      content:
          'This will unassign teacher profiles for all selected users. Continue?',
    );
    if (confirm != true) return;
    final selectedUsers = _users
        .where((u) => _selectedUserIds.contains(u.uid))
        .toList();
    final undoSnapshots = _snapshotsFromUsers(selectedUsers);
    await _runAction(
      message: 'Cleared teacher mapping for ${_selectedUserIds.length} users',
      undoSnapshots: undoSnapshots,
      action: () => Future.wait(
        selectedUsers.map((user) {
          return _service.updateUserAccess(
            uid: user.uid,
            role: user.role,
            linkedStudentIds: user.linkedStudentIds,
            teacherId: null,
          );
        }),
      ),
    );
  }

  Future<void> _runAction({
    required Future<void> Function() action,
    required String message,
    List<_UserAccessSnapshot> undoSnapshots = const [],
  }) async {
    setState(() => _isBusy = true);
    try {
      await action();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          action: undoSnapshots.isEmpty
              ? null
              : SnackBarAction(
                  label: 'UNDO',
                  onPressed: () => unawaited(_undoSnapshots(undoSnapshots)),
                ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Action failed. Please retry.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<bool?> _confirmAction({
    required String title,
    required String content,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        actionsOverflowDirection: VerticalDirection.down,
        actionsOverflowButtonSpacing: 8,
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  String _userLabel(UserAccessProfile user) {
    if (user.name.trim().isNotEmpty) return user.name;
    if (user.email.trim().isNotEmpty) return user.email;
    return user.uid;
  }

  Future<void> _exportFilteredUsersCsv() async {
    final rows = _filteredUsers;
    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No users available for export.')),
      );
      return;
    }
    final csv = _buildUsersCsv(rows);
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        actionsOverflowDirection: VerticalDirection.down,
        actionsOverflowButtonSpacing: 8,
        title: const Text('CSV Exported'),
        content: SizedBox(
          width: Responsive.controlWidth(context, preferred: 540),
          child: SingleChildScrollView(child: SelectableText(csv)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _openImportCsvDialog() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        actionsOverflowDirection: VerticalDirection.down,
        actionsOverflowButtonSpacing: 8,
        title: const Text('Import CSV'),
        content: SizedBox(
          width: Responsive.controlWidth(context, preferred: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Header: uid,name,email,role,teacherId,linkedStudentIds',
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 12,
                decoration: const InputDecoration(
                  hintText: 'Paste CSV data here',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use "|" inside linkedStudentIds, e.g. stu1|stu2',
                style: Theme.of(context).textTheme.bodySmall,
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
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    await _importUsersCsv(value);
  }

  Future<void> _importUsersCsv(String input) async {
    final rows = _parseCsvRows(input);
    if (rows.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV must include header and at least one row.'),
        ),
      );
      return;
    }
    final header = rows.first.map((e) => e.trim().toLowerCase()).toList();
    final uidIndex = header.indexOf('uid');
    final roleIndex = header.indexOf('role');
    if (uidIndex == -1 || roleIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV header must include uid and role columns.'),
        ),
      );
      return;
    }
    final teacherIndex = header.indexOf('teacherid');
    final linkedIndex = header.indexOf('linkedstudentids');

    final usersById = {for (final user in _users) user.uid: user};
    final updates = <String, _CsvAccessUpdate>{};
    var skippedRows = 0;

    String cellAt(List<String> row, int index) {
      if (index < 0 || index >= row.length) return '';
      return row[index].trim();
    }

    for (final row in rows.skip(1)) {
      if (row.every((cell) => cell.trim().isEmpty)) continue;
      final uid = cellAt(row, uidIndex);
      final role = _parseRoleStrict(cellAt(row, roleIndex));
      if (uid.isEmpty || role == null) {
        skippedRows++;
        continue;
      }
      final existing = usersById[uid];
      if (existing == null) {
        skippedRows++;
        continue;
      }

      final linked = linkedIndex == -1
          ? (role == AppRole.parent || role == AppRole.student
                ? List<String>.from(existing.linkedStudentIds)
                : <String>[])
          : _parseLinkedStudentIds(cellAt(row, linkedIndex));

      final teacher = teacherIndex == -1
          ? (role == AppRole.teacher ? existing.teacherId : null)
          : _normalizeOptional(cellAt(row, teacherIndex));

      updates[uid] = _CsvAccessUpdate(
        uid: uid,
        role: role,
        linkedStudentIds: role == AppRole.parent || role == AppRole.student
            ? linked
            : const [],
        teacherId: role == AppRole.teacher ? teacher : null,
      );
    }

    if (updates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid rows found for import.')),
      );
      return;
    }

    final undoSnapshots = updates.keys
        .map((uid) => _snapshotFromUser(usersById[uid]!))
        .toList();

    await _runAction(
      message:
          'Imported ${updates.length} users'
          '${skippedRows > 0 ? ' ($skippedRows skipped)' : ''}',
      undoSnapshots: undoSnapshots,
      action: () => Future.wait(
        updates.values.map((item) {
          return _service.updateUserAccess(
            uid: item.uid,
            role: item.role,
            linkedStudentIds: item.linkedStudentIds,
            teacherId: item.teacherId,
          );
        }),
      ),
    );
  }

  Future<void> _undoSnapshots(List<_UserAccessSnapshot> snapshots) async {
    if (snapshots.isEmpty || _isBusy) return;
    await _runAction(
      message: 'Changes reverted',
      action: () => Future.wait(
        snapshots.map((item) {
          return _service.updateUserAccess(
            uid: item.uid,
            role: item.role,
            linkedStudentIds: item.linkedStudentIds,
            teacherId: item.teacherId,
          );
        }),
      ),
    );
  }

  Future<void> _resolveTeacherProfileIssues() async {
    final missingUsers = _users
        .where(
          (u) =>
              u.role == AppRole.teacher &&
              (u.teacherId == null || u.teacherId!.isEmpty),
        )
        .toList();
    if (missingUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No teacher profile issues found.')),
      );
      return;
    }
    if (_teachers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No teacher profiles available to map.')),
      );
      return;
    }

    final byEmail = <String, List<SchoolTeacher>>{};
    final byName = <String, List<SchoolTeacher>>{};
    for (final teacher in _teachers) {
      final emailKey = teacher.email.trim().toLowerCase();
      final nameKey = teacher.name.trim().toLowerCase();
      if (emailKey.isNotEmpty) {
        byEmail.putIfAbsent(emailKey, () => <SchoolTeacher>[]).add(teacher);
      }
      if (nameKey.isNotEmpty) {
        byName.putIfAbsent(nameKey, () => <SchoolTeacher>[]).add(teacher);
      }
    }

    final matched = <_TeacherMatchUpdate>[];
    for (final user in missingUsers) {
      SchoolTeacher? selected;
      final userEmailKey = user.email.trim().toLowerCase();
      final userNameKey = user.name.trim().toLowerCase();

      final emailMatches = userEmailKey.isEmpty
          ? const <SchoolTeacher>[]
          : (byEmail[userEmailKey] ?? const <SchoolTeacher>[]);
      if (emailMatches.length == 1) {
        selected = emailMatches.first;
      } else {
        final nameMatches = userNameKey.isEmpty
            ? const <SchoolTeacher>[]
            : (byName[userNameKey] ?? const <SchoolTeacher>[]);
        if (nameMatches.length == 1) {
          selected = nameMatches.first;
        }
      }

      if (selected != null) {
        matched.add(_TeacherMatchUpdate(user: user, teacherId: selected.id));
      }
    }

    if (matched.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No unique teacher matches found. Map manually.'),
        ),
      );
      return;
    }

    final undoSnapshots = matched
        .map((m) => _snapshotFromUser(m.user))
        .toList();
    final unresolved = missingUsers.length - matched.length;
    await _runAction(
      message:
          'Resolved ${matched.length} teacher profile issues'
          '${unresolved > 0 ? ' ($unresolved unresolved)' : ''}',
      undoSnapshots: undoSnapshots,
      action: () => Future.wait(
        matched.map(
          (item) => _service.updateUserAccess(
            uid: item.user.uid,
            role: item.user.role,
            linkedStudentIds: item.user.linkedStudentIds,
            teacherId: item.teacherId,
          ),
        ),
      ),
    );
  }

  String _buildUsersCsv(List<UserAccessProfile> users) {
    final lines = <String>[
      'uid,name,email,role,teacherId,linkedStudentIds',
      ...users.map((user) {
        return [
          _csvEscape(user.uid),
          _csvEscape(user.name),
          _csvEscape(user.email),
          _csvEscape(user.role.value),
          _csvEscape(user.teacherId ?? ''),
          _csvEscape(user.linkedStudentIds.join('|')),
        ].join(',');
      }),
    ];
    return lines.join('\n');
  }

  List<List<String>> _parseCsvRows(String input) {
    final rows = <List<String>>[];
    final row = <String>[];
    final field = StringBuffer();
    var inQuotes = false;

    void pushField() {
      row.add(field.toString());
      field.clear();
    }

    void pushRow() {
      if (row.length == 1 && row.first.trim().isEmpty) {
        row.clear();
        return;
      }
      rows.add(List<String>.from(row));
      row.clear();
    }

    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (char == '"') {
        if (inQuotes && i + 1 < input.length && input[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }
      if (!inQuotes && char == ',') {
        pushField();
        continue;
      }
      if (!inQuotes && (char == '\n' || char == '\r')) {
        pushField();
        pushRow();
        if (char == '\r' && i + 1 < input.length && input[i + 1] == '\n') {
          i++;
        }
        continue;
      }
      field.write(char);
    }
    pushField();
    if (row.isNotEmpty) {
      pushRow();
    }
    return rows;
  }

  AppRole? _parseRoleStrict(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'admin':
        return AppRole.admin;
      case 'teacher':
        return AppRole.teacher;
      case 'parent':
        return AppRole.parent;
      case 'student':
        return AppRole.student;
      default:
        return null;
    }
  }

  List<String> _parseLinkedStudentIds(String raw) {
    if (raw.trim().isEmpty) return const [];
    return raw
        .split('|')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
  }

  String _csvEscape(String value) {
    final escaped = value.replaceAll('"', '""');
    final needsQuotes =
        escaped.contains(',') ||
        escaped.contains('"') ||
        escaped.contains('\n') ||
        escaped.contains('\r');
    return needsQuotes ? '"$escaped"' : escaped;
  }

  String? _normalizeOptional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  _UserAccessSnapshot _snapshotFromUser(UserAccessProfile user) {
    return _UserAccessSnapshot(
      uid: user.uid,
      role: user.role,
      linkedStudentIds: List<String>.from(user.linkedStudentIds),
      teacherId: user.teacherId,
    );
  }

  List<_UserAccessSnapshot> _snapshotsFromUsers(List<UserAccessProfile> users) {
    return users.map(_snapshotFromUser).toList();
  }

  void _bind(String uid) {
    _isLoading = true;
    _usersSub?.cancel();
    _studentsSub?.cancel();
    _teachersSub?.cancel();

    var usersReady = false;
    var studentsReady = false;
    var teachersReady = false;

    void finish() {
      if (!mounted) return;
      if (usersReady && studentsReady && teachersReady) {
        setState(() => _isLoading = false);
      }
    }

    _usersSub = _service.watchUserProfiles().listen((data) {
      if (!mounted) return;
      setState(() {
        _users = data;
        _selectedUserIds.removeWhere((id) => !_users.any((u) => u.uid == id));
      });
      usersReady = true;
      finish();
    });
    _studentsSub = _service.watchStudents(uid).listen((data) {
      if (!mounted) return;
      setState(() => _students = data);
      studentsReady = true;
      finish();
    });
    _teachersSub = _service.watchTeachers(uid).listen((data) {
      if (!mounted) return;
      setState(() => _teachers = data);
      teachersReady = true;
      finish();
    });
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

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final AppRole role;

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String label;
    switch (role) {
      case AppRole.admin:
        color = Colors.indigo;
        label = 'Admin';
      case AppRole.teacher:
        color = Colors.green;
        label = 'Teacher';
      case AppRole.parent:
        color = Colors.orange;
        label = 'Parent';
      case AppRole.student:
        color = Colors.purple;
        label = 'Student';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.14),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _TinyInfo extends StatelessWidget {
  const _TinyInfo({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _CsvAccessUpdate {
  const _CsvAccessUpdate({
    required this.uid,
    required this.role,
    required this.linkedStudentIds,
    required this.teacherId,
  });

  final String uid;
  final AppRole role;
  final List<String> linkedStudentIds;
  final String? teacherId;
}

class _UserAccessSnapshot {
  const _UserAccessSnapshot({
    required this.uid,
    required this.role,
    required this.linkedStudentIds,
    required this.teacherId,
  });

  final String uid;
  final AppRole role;
  final List<String> linkedStudentIds;
  final String? teacherId;
}

class _TeacherMatchUpdate {
  const _TeacherMatchUpdate({required this.user, required this.teacherId});

  final UserAccessProfile user;
  final String teacherId;
}
