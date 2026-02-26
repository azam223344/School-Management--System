import 'dart:async';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/module_ai_action_button.dart';
import '../../../../core/widgets/session_menu_button.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../dashboard/data/services/school_management_service.dart';
import '../../data/models/attendance_record.dart';
import '../controllers/attendance_controller.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final AttendanceController _controller = Get.find<AttendanceController>();
  final AuthProvider _auth = Get.find<AuthProvider>();
  final ThemeProvider _theme = Get.find<ThemeProvider>();

  String? _boundUid;
  AppRole _role = AppRole.admin;
  List<String> _linkedStudentIds = const [];
  String? _currentUserEmail;
  String? _mappedTeacherId;

  DateTime _selectedDate = DateTime.now();
  String? _selectedClassId;
  String _studentSearch = '';

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
    if (Get.isRegistered<AttendanceController>()) {
      Get.delete<AttendanceController>();
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
        title: const Text('Attendance'),
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
          const ModuleAiActionButton(moduleName: 'Attendance'),
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
                              ? 'Local mode: attendance not synced to cloud.'
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
                        _buildFilters(),
                        const SizedBox(height: 12),
                        _buildMarkingPanel(),
                        const SizedBox(height: 12),
                        _buildRecordsPanel(),
                        const SizedBox(height: 12),
                        _buildMonthlyReportPanel(),
                        const SizedBox(height: 12),
                        _buildChartsPanel(),
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

  List<SchoolClass> get _visibleClasses =>
      _filterClassesByRole(_controller.classes, _controller.teachers);

  List<SchoolStudent> get _visibleStudents =>
      _filterStudentsByRole(_controller.students, _visibleClasses);

  List<AttendanceRecord> get _records => _controller.records;

  Widget _buildFilters() {
    final classes = _visibleClasses;
    if (_selectedClassId != null &&
        classes.where((c) => c.id == _selectedClassId).isEmpty) {
      _selectedClassId = classes.isEmpty ? null : classes.first.id;
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_rounded),
              label: Text(_formatDate(_selectedDate)),
            ),
            SizedBox(
              width: Responsive.controlWidth(context, preferred: 260),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedClassId,
                decoration: const InputDecoration(labelText: 'Class'),
                items: classes
                    .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedClassId = value),
              ),
            ),
            SizedBox(
              width: Responsive.controlWidth(context, preferred: 260),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  labelText: 'Filter Students',
                  hintText: 'Name or roll',
                ),
                onChanged: (value) => setState(() => _studentSearch = value),
              ),
            ),
            FilledButton.icon(
              onPressed: _exportCsv,
              icon: const Icon(Icons.download_rounded),
              label: const Text('Copy CSV'),
            ),
            OutlinedButton.icon(
              onPressed: _saveCsvToFile,
              icon: const Icon(Icons.save_alt_rounded),
              label: const Text('Save CSV'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkingPanel() {
    final canEditAttendance =
        _role == AppRole.admin || _role == AppRole.teacher;
    final selectedClass = _visibleClasses
        .where((c) => c.id == _selectedClassId)
        .firstOrNull;
    if (selectedClass == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Select a class to mark attendance.'),
        ),
      );
    }

    final classStudents = selectedClass.studentIds
        .map((id) => _visibleStudents.where((s) => s.id == id).firstOrNull)
        .whereType<SchoolStudent>()
        .where((s) {
          final q = _studentSearch.trim().toLowerCase();
          if (q.isEmpty) return true;
          return s.name.toLowerCase().contains(q) ||
              s.rollNumber.toLowerCase().contains(q);
        })
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mark Attendance • ${selectedClass.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (classStudents.isEmpty)
              const Text('No students found for selected filters.')
            else
              ...classStudents.map((student) {
                final record = _records.where((r) {
                  return r.classId == selectedClass.id &&
                      _isSameDate(r.date, _selectedDate) &&
                      r.studentId == student.id;
                }).firstOrNull;
                final present = record?.present ?? false;

                return CheckboxListTile(
                  title: Text(student.name),
                  subtitle: Text('Roll: ${student.rollNumber}'),
                  value: present,
                  onChanged: !canEditAttendance
                      ? null
                      : (value) {
                          if (value == null) return;
                          _controller.upsertRecord(
                            classId: selectedClass.id,
                            studentId: student.id,
                            date: _selectedDate,
                            present: value,
                          );
                        },
                );
              }),
            const SizedBox(height: 6),
            if (canEditAttendance)
              FilledButton.icon(
                onPressed: _saveAttendance,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save Attendance'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsPanel() {
    final dateRecords =
        _records.where((r) => _isSameDate(r.date, _selectedDate)).toList()
          ..sort((a, b) => a.classId.compareTo(b.classId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date-wise Records • ${_formatDate(_selectedDate)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (dateRecords.isEmpty)
              const Text('No attendance records for this date.')
            else
              ...dateRecords.map((r) {
                final student = _visibleStudents
                    .where((s) => s.id == r.studentId)
                    .firstOrNull;
                final schoolClass = _visibleClasses
                    .where((c) => c.id == r.classId)
                    .firstOrNull;
                return ListTile(
                  dense: true,
                  leading: Icon(
                    r.present
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: r.present ? Colors.green : Colors.red,
                  ),
                  title: Text(student?.name ?? 'Student'),
                  subtitle: Text('Class: ${schoolClass?.name ?? '-'}'),
                  trailing: Text(r.present ? 'Present' : 'Absent'),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyReportPanel() {
    final monthly = _records.where((r) {
      final sameMonth =
          r.date.year == _selectedDate.year &&
          r.date.month == _selectedDate.month;
      final classOk = _selectedClassId == null || r.classId == _selectedClassId;
      return sameMonth && classOk;
    }).toList();

    final total = monthly.length;
    final present = monthly.where((e) => e.present).length;
    final percent = total == 0 ? 0.0 : present / total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Report • ${_monthName(_selectedDate.month)} ${_selectedDate.year}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _SummaryChip(
                    label: 'Present',
                    value: present.toString(),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryChip(
                    label: 'Absent',
                    value: (total - present).toString(),
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryChip(
                    label: 'Rate',
                    value: '${(percent * 100).toStringAsFixed(1)}%',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: percent),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsPanel() {
    final monthly = _records.where((r) {
      return r.date.year == _selectedDate.year &&
          r.date.month == _selectedDate.month;
    }).toList();

    final classRates = <String, double>{};
    for (final schoolClass in _visibleClasses) {
      final entries = monthly
          .where((r) => r.classId == schoolClass.id)
          .toList();
      if (entries.isEmpty) continue;
      final present = entries.where((e) => e.present).length;
      classRates[schoolClass.name] = present / entries.length;
    }

    final studentRates = <String, double>{};
    for (final student in _visibleStudents) {
      final entries = monthly.where((r) => r.studentId == student.id).toList();
      if (entries.isEmpty) continue;
      final present = entries.where((e) => e.present).length;
      studentRates[student.name] = present / entries.length;
    }

    final topStudents = studentRates.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Charts • ${_monthName(_selectedDate.month)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text('Class-wise', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            if (classRates.isEmpty)
              const Text('No class chart data for this month.')
            else
              ...classRates.entries.map((entry) {
                return _RateBar(label: entry.key, value: entry.value);
              }),
            const SizedBox(height: 10),
            Text('Top Students', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            if (topStudents.isEmpty)
              const Text('No student chart data for this month.')
            else
              ...topStudents.take(8).map((entry) {
                return _RateBar(label: entry.key, value: entry.value);
              }),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(
        () => _selectedDate = DateTime(picked.year, picked.month, picked.day),
      );
    }
  }

  Future<void> _saveAttendance() async {
    if (_controller.isLocalMode.value) {
      _showMessage('Saved locally. Retry sync when cloud is ready.');
      return;
    }
    await _controller.saveAttendance();
    if (_controller.isLocalMode.value) {
      _showError('Cloud sync failed. Data kept locally.');
      return;
    }
    _showMessage('Attendance saved.');
  }

  String _formatDate(DateTime d) {
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$month-$day';
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<SchoolClass> _filterClassesByRole(
    List<SchoolClass> classes,
    List<SchoolTeacher> teachers,
  ) {
    if (_role == AppRole.admin) {
      return classes;
    }
    if (_role == AppRole.teacher) {
      if (_mappedTeacherId != null && _mappedTeacherId!.isNotEmpty) {
        return classes
            .where(
              (c) => c.teacherId != null && c.teacherId == _mappedTeacherId,
            )
            .toList();
      }
      final teacherIds = teachers
          .where(
            (t) =>
                _currentUserEmail != null &&
                t.email.toLowerCase() == _currentUserEmail!.toLowerCase(),
          )
          .map((e) => e.id)
          .toSet();
      return classes
          .where((c) => c.teacherId != null && teacherIds.contains(c.teacherId))
          .toList();
    }
    final linked = _linkedStudentIds.toSet();
    return classes.where((c) => c.studentIds.any(linked.contains)).toList();
  }

  List<SchoolStudent> _filterStudentsByRole(
    List<SchoolStudent> students,
    List<SchoolClass> classes,
  ) {
    if (_role == AppRole.admin) {
      return students;
    }
    if (_role == AppRole.teacher) {
      final allowedStudentIds = classes.expand((c) => c.studentIds).toSet();
      return students.where((s) => allowedStudentIds.contains(s.id)).toList();
    }
    final linked = _linkedStudentIds.toSet();
    return students.where((s) => linked.contains(s.id)).toList();
  }

  String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month - 1];
  }

  Future<void> _exportCsv() async {
    final csv = _buildCsv();
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    _showMessage('CSV copied to clipboard (${_records.length} rows).');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, controller) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: ListView(
              controller: controller,
              children: [
                Text(
                  'Attendance CSV',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                SelectableText(csv),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveCsvToFile() async {
    final csv = _buildCsv();
    final filename =
        'attendance_${DateTime.now().millisecondsSinceEpoch.toString()}.csv';

    try {
      Directory? target;
      if (Platform.isAndroid) {
        target = await _androidDownloadDirectory();
      }
      target ??= await getApplicationDocumentsDirectory();

      final file = File('${target.path}/$filename');
      await file.writeAsString(csv);
      if (!mounted) return;
      _showSavedFileSnack(file.path, target.path);
    } catch (error) {
      if (!mounted) return;
      _showError('Failed to save CSV file: $error');
    }
  }

  Future<Directory?> _androidDownloadDirectory() async {
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted && !status.isLimited && !status.isProvisional) {
        return null;
      }
      final download = Directory('/storage/emulated/0/Download');
      if (await download.exists()) {
        return download;
      }
    } catch (_) {
      // Fallback to app directory below.
    }
    return null;
  }

  String _buildCsv() {
    final rows = <String>['date,class,student,status'];
    for (final record in _records) {
      final schoolClass = _visibleClasses
          .where((c) => c.id == record.classId)
          .firstOrNull;
      final student = _visibleStudents
          .where((s) => s.id == record.studentId)
          .firstOrNull;
      rows.add(
        '${_formatDate(record.date)},${_csv(schoolClass?.name ?? '-')},${_csv(student?.name ?? '-')},${record.present ? 'Present' : 'Absent'}',
      );
    }
    return rows.join('\n');
  }

  String _csv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  void _showSavedFileSnack(String filePath, String folderPath) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        actionsOverflowDirection: VerticalDirection.down,
        actionsOverflowButtonSpacing: 8,
        title: const Text('CSV Saved'),
        content: SelectableText(filePath),
        actions: [
          TextButton(
            onPressed: () {
              unawaited(Clipboard.setData(ClipboardData(text: filePath)));
              Navigator.pop(dialogContext);
              _showMessage('Path copied to clipboard.');
            },
            child: const Text('Copy Path'),
          ),
          if (Platform.isAndroid)
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _openFolderAndroid(folderPath);
              },
              child: const Text('Open Folder'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _openFolderAndroid(String folderPath) async {
    if (!Platform.isAndroid) return;
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: Uri.encodeFull('file://$folderPath'),
        type: 'resource/folder',
      );
      await intent.launch();
    } catch (_) {
      if (!mounted) return;
      _showError('Could not open folder automatically. Path: $folderPath');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
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

class _RateBar extends StatelessWidget {
  const _RateBar({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
              Text('${(value * 100).toStringAsFixed(1)}%'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: value),
        ],
      ),
    );
  }
}
