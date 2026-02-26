import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../config/routes/route_constants.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/module_ai_action_button.dart';
import '../../../../core/widgets/session_menu_button.dart';
import '../../../../features/auth/data/models/user_model.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../data/services/school_management_service.dart';

enum _StudentSort { nameAsc, nameDesc, gradeAsc, gradeDesc }

enum _TeacherSort { nameAsc, nameDesc, subjectAsc, subjectDesc }

enum _TargetType { student, teacher, schoolClass }

enum _OverviewModule {
  exams,
  fees,
  library,
  timetable,
  transport,
  notifications,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.initialNavIndex = 0,
    this.initialOverviewModule,
  });

  final int initialNavIndex;
  final String? initialOverviewModule;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthProvider _auth = Get.find<AuthProvider>();
  final ThemeProvider _theme = Get.find<ThemeProvider>();
  final SchoolManagementService _service = SchoolManagementService();

  int _selectedIndex = 0;
  String? _activeUid;
  bool _isSyncing = false;
  String? _syncError;
  bool _isLocalMode = true;
  int _localCounter = 0;

  StreamSubscription<List<SchoolStudent>>? _studentsSub;
  StreamSubscription<List<SchoolTeacher>>? _teachersSub;
  StreamSubscription<List<SchoolClass>>? _classesSub;
  StreamSubscription<Map<String, dynamic>>? _modulesSub;

  List<SchoolStudent> _students = const [];
  List<SchoolTeacher> _teachers = const [];
  List<SchoolClass> _classes = const [];

  bool _studentsReady = false;
  bool _teachersReady = false;
  bool _classesReady = false;
  bool _modulesReady = false;

  String _studentSearch = '';
  String _teacherSearch = '';
  _StudentSort _studentSort = _StudentSort.nameAsc;
  _TeacherSort _teacherSort = _TeacherSort.nameAsc;
  _OverviewModule _activeModule = _OverviewModule.exams;

  List<_ExamItem> _examItems = const [];
  List<_FeeItem> _feeItems = const [];
  List<_LibraryItem> _libraryItems = const [];
  List<_TimetableItem> _timetableItems = const [];
  List<_TransportItem> _transportItems = const [];
  List<_NotificationItem> _notificationItems = const [];

  void _onAppStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onAppStateChanged);
    _theme.addListener(_onAppStateChanged);
    _selectedIndex = widget.initialNavIndex.clamp(0, 3);
    _activeModule = _moduleFromName(widget.initialOverviewModule);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAppStateChanged);
    _theme.removeListener(_onAppStateChanged);
    _cancelStreams();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.user;
    final isDarkMode = _theme.isDarkMode;

    return Scaffold(
      drawer: _buildAppDrawer(),
      appBar: AppBar(
        title: const Text('School Management'),
        actions: [
          const ModuleAiActionButton(moduleName: 'Dashboard'),
          const SessionMenuButton(),
          IconButton(
            tooltip: isDarkMode
                ? 'Switch to light mode'
                : 'Switch to dark mode',
            onPressed: () => _theme.toggleTheme(!isDarkMode),
            icon: Icon(
              isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
          if (user?.emailVerified != true)
            IconButton(
              tooltip: 'Verify Email',
              onPressed: () => Get.toNamed(RouteConstants.verifyEmail),
              icon: const Icon(Icons.verified_outlined),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final pageContent = _buildPageWithLayout(constraints.maxWidth);
          final content = Stack(
            children: [
              Column(
                children: [
                  if (_isLocalMode) _buildStatusBanner(),
                  Expanded(child: pageContent),
                ],
              ),
              if (_isSyncing)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: Color(0x88FFFFFF),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
            ],
          );

          if (isWide) {
            return Row(
              children: [
                NavigationRail(
                  extended: constraints.maxWidth >= 1200,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() => _selectedIndex = value);
                  },
                  labelType: constraints.maxWidth >= 1200
                      ? null
                      : NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard_rounded),
                      label: Text('Overview'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.school_outlined),
                      selectedIcon: Icon(Icons.school_rounded),
                      label: Text('Students'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.badge_outlined),
                      selectedIcon: Icon(Icons.badge_rounded),
                      label: Text('Teachers'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.class_outlined),
                      selectedIcon: Icon(Icons.class_rounded),
                      label: Text('Classes'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            );
          }

          return Column(
            children: [
              Expanded(child: content),
              NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (value) {
                  setState(() => _selectedIndex = value);
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard_rounded),
                    label: 'Overview',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.school_outlined),
                    selectedIcon: Icon(Icons.school_rounded),
                    label: 'Students',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.badge_outlined),
                    selectedIcon: Icon(Icons.badge_rounded),
                    label: 'Teachers',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.class_outlined),
                    selectedIcon: Icon(Icons.class_rounded),
                    label: 'Classes',
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppDrawer() {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const ListTile(
              title: Text(
                'School Management Modules',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.blueAccent,
                ),
              ),
            ),
            _drawerTile(
              'Dashboard',
              Icons.dashboard_rounded,
              RouteConstants.home,
            ),
            _drawerTile(
              'Students',
              Icons.school_rounded,
              RouteConstants.students,
            ),
            _drawerTile(
              'Teachers',
              Icons.badge_rounded,
              RouteConstants.teachers,
            ),
            _drawerTile('Classes', Icons.class_rounded, RouteConstants.classes),
            _drawerTile(
              'Subjects',
              Icons.book_rounded,
              RouteConstants.subjects,
            ),
            _drawerTile(
              'Attendance',
              Icons.fact_check_rounded,
              RouteConstants.attendance,
            ),
            _drawerTile(
              'Exams',
              Icons.assignment_rounded,
              RouteConstants.exams,
            ),
            _drawerTile(
              'Results',
              Icons.leaderboard_rounded,
              RouteConstants.results,
            ),
            _drawerTile('Fees', Icons.payments_rounded, RouteConstants.fees),
            _drawerTile(
              'Notifications',
              Icons.notifications_rounded,
              RouteConstants.notifications,
            ),
            _drawerTile(
              'Timetable',
              Icons.schedule_rounded,
              RouteConstants.timetable,
            ),
            _drawerTile(
              'Library',
              Icons.menu_book_rounded,
              RouteConstants.library,
            ),
            _drawerTile(
              'Transport',
              Icons.directions_bus_rounded,
              RouteConstants.transport,
            ),
            _drawerTile(
              'Chatbot',
              Icons.smart_toy_rounded,
              RouteConstants.chatbot,
            ),
            _drawerTile(
              'Predictive Analytics',
              Icons.query_stats_rounded,
              RouteConstants.predictiveAnalytics,
            ),
            _drawerTile(
              'Admin Automation',
              Icons.settings_suggest_rounded,
              RouteConstants.adminAutomation,
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(String title, IconData icon, String route) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        if (ModalRoute.of(context)?.settings.name == route) {
          return;
        }
        Get.offNamed(route);
      },
    );
  }

  void _bindData(String uid) {
    _cancelStreams();
    setState(() {
      _syncError = null;
      _isLocalMode = false;
      _isSyncing = true;
      _studentsReady = false;
      _teachersReady = false;
      _classesReady = false;
      _modulesReady = false;
    });

    _studentsSub = _service.watchStudents(uid).listen((data) {
      if (!mounted) {
        return;
      }
      setState(() {
        _students = data;
        _studentsReady = true;
        _isSyncing =
            !(_studentsReady &&
                _teachersReady &&
                _classesReady &&
                _modulesReady);
      });
    }, onError: _onSyncError);

    _teachersSub = _service.watchTeachers(uid).listen((data) {
      if (!mounted) {
        return;
      }
      setState(() {
        _teachers = data;
        _teachersReady = true;
        _isSyncing =
            !(_studentsReady &&
                _teachersReady &&
                _classesReady &&
                _modulesReady);
      });
    }, onError: _onSyncError);

    _classesSub = _service.watchClasses(uid).listen((data) {
      if (!mounted) {
        return;
      }
      setState(() {
        _classes = data;
        _classesReady = true;
        _isSyncing =
            !(_studentsReady &&
                _teachersReady &&
                _classesReady &&
                _modulesReady);
      });
    }, onError: _onSyncError);

    _modulesSub = _service.watchModules(uid).listen((data) {
      if (!mounted) {
        return;
      }
      _safeSetState(() {
        _examItems = _parseExamItems(data['exams']);
        _feeItems = _parseFeeItems(data['fees']);
        _libraryItems = _parseLibraryItems(data['library']);
        _timetableItems = _parseTimetableItems(data['timetable']);
        _transportItems = _parseTransportItems(data['transport']);
        _notificationItems = _parseNotificationItems(data['notifications']);
        _modulesReady = true;
        _isSyncing =
            !(_studentsReady &&
                _teachersReady &&
                _classesReady &&
                _modulesReady);
      });
    }, onError: _onSyncError);
  }

  void _onSyncError(Object error) {
    if (!mounted) {
      return;
    }
    final message = _toFriendlySyncError(error.toString());
    if (_syncError == message && _isLocalMode) {
      return;
    }
    _cancelStreams();
    setState(() {
      _isSyncing = false;
      _syncError = message;
      _isLocalMode = true;
    });
  }

  void _cancelStreams() {
    _studentsSub?.cancel();
    _teachersSub?.cancel();
    _classesSub?.cancel();
    _modulesSub?.cancel();
    _studentsSub = null;
    _teachersSub = null;
    _classesSub = null;
    _modulesSub = null;
  }

  Widget _buildPageWithLayout(double width) {
    final horizontal = width >= 1200
        ? 28.0
        : width >= 800
        ? 20.0
        : 12.0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontal, 14, horizontal, 14),
          child: _buildPage(width),
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    final details = (_syncError ?? '').trim();
    return Material(
      color: Colors.amber.shade100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded),
            SizedBox(
              width: Responsive.controlWidth(context, preferred: 220),
              child: Text(
                details.isEmpty
                    ? 'Running in local mode. Data will not sync to Firestore.'
                    : 'Running in local mode. $details',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: _tryCloudSync,
              child: const Text('Retry Sync'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(double width) {
    switch (_selectedIndex) {
      case 1:
        return _buildStudentsPage(width);
      case 2:
        return _buildTeachersPage(width);
      case 3:
        return _buildClassesPage(width);
      default:
        return _buildOverviewPage(width);
    }
  }

  List<SchoolStudent> get _filteredStudents {
    var list = _students.where((student) {
      final q = _studentSearch.trim().toLowerCase();
      if (q.isEmpty) {
        return true;
      }
      return student.name.toLowerCase().contains(q) ||
          student.rollNumber.toLowerCase().contains(q) ||
          student.grade.toLowerCase().contains(q) ||
          student.phoneNumber.toLowerCase().contains(q) ||
          student.parentName.toLowerCase().contains(q) ||
          student.studentIdentityNumber.toLowerCase().contains(q) ||
          student.parentIdentityNumber.toLowerCase().contains(q) ||
          student.age.toLowerCase().contains(q);
    }).toList();

    switch (_studentSort) {
      case _StudentSort.nameAsc:
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case _StudentSort.nameDesc:
        list.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
      case _StudentSort.gradeAsc:
        list.sort(
          (a, b) => a.grade.toLowerCase().compareTo(b.grade.toLowerCase()),
        );
      case _StudentSort.gradeDesc:
        list.sort(
          (a, b) => b.grade.toLowerCase().compareTo(a.grade.toLowerCase()),
        );
    }
    return list;
  }

  List<SchoolTeacher> get _filteredTeachers {
    var list = _teachers.where((teacher) {
      final q = _teacherSearch.trim().toLowerCase();
      if (q.isEmpty) {
        return true;
      }
      return teacher.name.toLowerCase().contains(q) ||
          teacher.subject.toLowerCase().contains(q) ||
          teacher.email.toLowerCase().contains(q) ||
          teacher.qualifications.toLowerCase().contains(q) ||
          teacher.phoneNumber.toLowerCase().contains(q) ||
          teacher.identityNumber.toLowerCase().contains(q);
    }).toList();

    switch (_teacherSort) {
      case _TeacherSort.nameAsc:
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case _TeacherSort.nameDesc:
        list.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
      case _TeacherSort.subjectAsc:
        list.sort(
          (a, b) => a.subject.toLowerCase().compareTo(b.subject.toLowerCase()),
        );
      case _TeacherSort.subjectDesc:
        list.sort(
          (a, b) => b.subject.toLowerCase().compareTo(a.subject.toLowerCase()),
        );
    }
    return list;
  }

  Widget _buildOverviewPage(double width) {
    final attendanceEntries = _classes
        .expand((schoolClass) => schoolClass.attendance.values)
        .toList();
    final presentCount = attendanceEntries.where((value) => value).length;
    final attendanceRate = attendanceEntries.isEmpty
        ? 0
        : (presentCount / attendanceEntries.length * 100).round();

    final cards = [
      _StatsCard(
        title: 'Students',
        value: _students.length.toString(),
        icon: Icons.school_rounded,
        color: const Color(0xFF0EA5E9),
        footnote: 'Enrolled learners',
      ),
      _StatsCard(
        title: 'Teachers',
        value: _teachers.length.toString(),
        icon: Icons.badge_rounded,
        color: const Color(0xFF16A34A),
        footnote: 'Active faculty',
      ),
      _StatsCard(
        title: 'Classes',
        value: _classes.length.toString(),
        icon: Icons.class_rounded,
        color: const Color(0xFF6366F1),
        footnote: 'Running sections',
      ),
      _StatsCard(
        title: 'Attendance',
        value: '$attendanceRate%',
        icon: Icons.fact_check_rounded,
        color: const Color(0xFFF97316),
        footnote: 'Current trend',
      ),
    ];

    final isCompact = width < 700;
    final moduleCounts = <String, int>{
      'Exams': _examItems.length,
      'Fees': _feeItems.length,
      'Library': _libraryItems.length,
      'Timetable': _timetableItems.length,
      'Transport': _transportItems.length,
      'Notices': _notificationItems.length,
    };
    final moduleMax = moduleCounts.values.fold<int>(1, (a, b) => a > b ? a : b);
    final topModuleEntry = moduleCounts.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0B1F3A),
                  Color(0xFF0E3A6D),
                  Color(0xFF1550A8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x332A3F8B),
                  blurRadius: 34,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -44,
                  right: -28,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -52,
                  left: -20,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.11),
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_graph_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${topModuleEntry.key}: ${topModuleEntry.value}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(isCompact ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Academic Year 2026',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Overview Command Center',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Track academics, fees, library, transport and notices from a single smart dashboard.',
                        style: TextStyle(color: Colors.white70, height: 1.35),
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: LinearProgressIndicator(
                          minHeight: 10,
                          value: attendanceRate / 100,
                          backgroundColor: Colors.white24,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Campus attendance trend: $attendanceRate%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _dashboardQuickActions(),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _HeroPill(
                            icon: Icons.fact_check_rounded,
                            text: 'Attendance $attendanceRate%',
                          ),
                          _HeroPill(
                            icon: Icons.assignment_turned_in_rounded,
                            text: '${_examItems.length} Exams',
                          ),
                          _HeroPill(
                            icon: Icons.notifications_active_rounded,
                            text: '${_notificationItems.length} Notices',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Module Activity',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  ...moduleCounts.entries.map((entry) {
                    final value = moduleMax == 0
                        ? 0.0
                        : entry.value / moduleMax;
                    return _ModuleActivityRow(
                      label: entry.key,
                      count: entry.value,
                      value: value,
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Recommendation',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    topModuleEntry.value == 0
                        ? 'Start by adding module entries to activate trends and planning insights.'
                        : 'Highest activity is in ${topModuleEntry.key}. Prioritize data quality checks there first for better reporting.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 960
                  ? 4
                  : constraints.maxWidth >= 680
                  ? 2
                  : 1;
              final textScale = MediaQuery.textScalerOf(
                context,
              ).scale(1).clamp(1.0, 2.0);
              final baseExtent = crossAxisCount == 1 ? 146.0 : 138.0;
              final mainAxisExtent =
                  baseExtent + ((textScale - 1.0) * 26.0).clamp(0.0, 30.0);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cards.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  mainAxisExtent: mainAxisExtent,
                ),
                itemBuilder: (context, index) => cards[index],
              );
            },
          ),
          const SizedBox(height: 18),
          Text('Campus Modules', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _OverviewModule.values.map((module) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_moduleLabel(module)),
                    selected: _activeModule == module,
                    avatar: Icon(
                      _moduleIcon(module),
                      size: 16,
                      color: _activeModule == module
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                    ),
                    onSelected: (_) => setState(() => _activeModule = module),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          _buildOverviewModuleCard(width),
        ],
      ),
    );
  }

  String _moduleLabel(_OverviewModule module) {
    switch (module) {
      case _OverviewModule.exams:
        return 'Exams';
      case _OverviewModule.fees:
        return 'Fees';
      case _OverviewModule.library:
        return 'Library';
      case _OverviewModule.timetable:
        return 'Timetable';
      case _OverviewModule.transport:
        return 'Transport';
      case _OverviewModule.notifications:
        return 'Notifications';
    }
  }

  _OverviewModule _moduleFromName(String? name) {
    switch (name) {
      case 'exams':
        return _OverviewModule.exams;
      case 'fees':
        return _OverviewModule.fees;
      case 'library':
        return _OverviewModule.library;
      case 'timetable':
        return _OverviewModule.timetable;
      case 'transport':
        return _OverviewModule.transport;
      case 'notifications':
        return _OverviewModule.notifications;
      default:
        return _OverviewModule.exams;
    }
  }

  IconData _moduleIcon(_OverviewModule module) {
    switch (module) {
      case _OverviewModule.exams:
        return Icons.assignment_rounded;
      case _OverviewModule.fees:
        return Icons.payments_rounded;
      case _OverviewModule.library:
        return Icons.menu_book_rounded;
      case _OverviewModule.timetable:
        return Icons.schedule_rounded;
      case _OverviewModule.transport:
        return Icons.directions_bus_rounded;
      case _OverviewModule.notifications:
        return Icons.notifications_active_rounded;
    }
  }

  List<Widget> _dashboardQuickActions() {
    return [
      _DashboardQuickActionChip(
        icon: Icons.person_add_alt_1_rounded,
        label: 'Add Student',
        onTap: _openCreateStudentDialog,
      ),
      _DashboardQuickActionChip(
        icon: Icons.badge_rounded,
        label: 'Add Teacher',
        onTap: _openCreateTeacherDialog,
      ),
      _DashboardQuickActionChip(
        icon: Icons.add_business_rounded,
        label: 'Create Class',
        onTap: _openCreateClassDialog,
      ),
      _DashboardQuickActionChip(
        icon: Icons.psychology_alt_rounded,
        label: 'Ask AI',
        onTap: () => Get.toNamed(
          RouteConstants.chatbot,
          arguments: const <String, String>{
            'module': 'Dashboard',
            'prompt':
                'Give me a dashboard health summary and top next actions.',
          },
        ),
      ),
    ];
  }

  Widget _buildOverviewModuleCard(double width) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surfaceContainerHighest,
            Theme.of(context).colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModuleHeader(),
            const SizedBox(height: 10),
            _buildModuleBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleHeader() {
    switch (_activeModule) {
      case _OverviewModule.exams:
        return _buildSectionHeader(
          title: 'Exam Management',
          actionLabel: 'Add Exam',
          onAction: _openAddExamDialog,
          isCompact: false,
        );
      case _OverviewModule.fees:
        return _buildSectionHeader(
          title: 'Fee Tracking',
          actionLabel: 'Add Fee',
          onAction: _openAddFeeDialog,
          isCompact: false,
        );
      case _OverviewModule.library:
        return _buildSectionHeader(
          title: 'Library Issues',
          actionLabel: 'Issue Book',
          onAction: _openAddLibraryDialog,
          isCompact: false,
        );
      case _OverviewModule.timetable:
        return _buildSectionHeader(
          title: 'Timetable',
          actionLabel: 'Add Slot',
          onAction: _openAddTimetableDialog,
          isCompact: false,
        );
      case _OverviewModule.transport:
        return _buildSectionHeader(
          title: 'Transport',
          actionLabel: 'Add Route',
          onAction: _openAddTransportDialog,
          isCompact: false,
        );
      case _OverviewModule.notifications:
        return _buildSectionHeader(
          title: 'Notifications',
          actionLabel: 'Send Notice',
          onAction: _openAddNotificationDialog,
          isCompact: false,
        );
    }
  }

  Widget _buildModuleBody() {
    switch (_activeModule) {
      case _OverviewModule.exams:
        if (_examItems.isEmpty) {
          return const _EmptyState(message: 'No exams scheduled yet.');
        }
        return _SimpleModuleList(
          children: _examItems.map((item) {
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.assignment)),
              title: Text(item.title),
              subtitle: Text(
                '${item.date} | ${item.subject} | ${_targetTitle(item.targetType, item.targetId)}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () => _updateModules(() {
                  _examItems = _examItems
                      .where((e) => e.id != item.id)
                      .toList();
                }),
              ),
            );
          }).toList(),
        );
      case _OverviewModule.fees:
        if (_feeItems.isEmpty) {
          return const _EmptyState(message: 'No fee records yet.');
        }
        return _SimpleModuleList(
          children: _feeItems.map((item) {
            return ListTile(
              leading: CircleAvatar(
                child: Icon(
                  item.paid
                      ? Icons.check_rounded
                      : Icons.currency_rupee_rounded,
                ),
              ),
              title: Text(item.title),
              subtitle: Text(
                '${item.amount} due ${item.dueDate} | ${_targetTitle(item.targetType, item.targetId)}',
              ),
              trailing: Wrap(
                spacing: 6,
                children: [
                  IconButton(
                    icon: Icon(
                      item.paid
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                    ),
                    onPressed: () => _updateModules(() {
                      _feeItems = _feeItems.map((fee) {
                        if (fee.id != item.id) return fee;
                        return fee.copyWith(paid: !fee.paid);
                      }).toList();
                    }),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => _updateModules(() {
                      _feeItems = _feeItems
                          .where((e) => e.id != item.id)
                          .toList();
                    }),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      case _OverviewModule.library:
        if (_libraryItems.isEmpty) {
          return const _EmptyState(message: 'No library issues yet.');
        }
        return _SimpleModuleList(
          children: _libraryItems.map((item) {
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.menu_book_rounded)),
              title: Text(item.bookName),
              subtitle: Text(
                'Issued to ${_targetTitle(item.targetType, item.targetId)} | Due ${item.dueDate}',
              ),
              trailing: Wrap(
                spacing: 6,
                children: [
                  IconButton(
                    icon: Icon(
                      item.returned
                          ? Icons.assignment_returned_rounded
                          : Icons.assignment_late_outlined,
                    ),
                    onPressed: () => _updateModules(() {
                      _libraryItems = _libraryItems.map((entry) {
                        if (entry.id != item.id) return entry;
                        return entry.copyWith(returned: !entry.returned);
                      }).toList();
                    }),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => _updateModules(() {
                      _libraryItems = _libraryItems
                          .where((e) => e.id != item.id)
                          .toList();
                    }),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      case _OverviewModule.timetable:
        if (_timetableItems.isEmpty) {
          return const _EmptyState(message: 'No timetable slots yet.');
        }
        return _SimpleModuleList(
          children: _timetableItems.map((item) {
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.schedule_rounded)),
              title: Text('${item.day} • ${item.time}'),
              subtitle: Text(
                '${item.subject} | ${_targetTitle(_TargetType.schoolClass, item.classId)} | ${_teacherName(item.teacherId)}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () => _updateModules(() {
                  _timetableItems = _timetableItems
                      .where((e) => e.id != item.id)
                      .toList();
                }),
              ),
            );
          }).toList(),
        );
      case _OverviewModule.transport:
        if (_transportItems.isEmpty) {
          return const _EmptyState(message: 'No transport routes yet.');
        }
        return _SimpleModuleList(
          children: _transportItems.map((item) {
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.directions_bus)),
              title: Text('${item.routeName} (${item.vehicleNo})'),
              subtitle: Text(
                '${item.driver} | ${_targetTitle(item.targetType, item.targetId)}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () => _updateModules(() {
                  _transportItems = _transportItems
                      .where((e) => e.id != item.id)
                      .toList();
                }),
              ),
            );
          }).toList(),
        );
      case _OverviewModule.notifications:
        if (_notificationItems.isEmpty) {
          return const _EmptyState(message: 'No notifications sent yet.');
        }
        return _SimpleModuleList(
          children: _notificationItems.map((item) {
            return ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.notifications_active_rounded),
              ),
              title: Text(item.title),
              subtitle: Text(
                '${item.message}\n${item.date} | ${_targetTitle(item.targetType, item.targetId)}',
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () => _updateModules(() {
                  _notificationItems = _notificationItems
                      .where((e) => e.id != item.id)
                      .toList();
                }),
              ),
            );
          }).toList(),
        );
    }
  }

  List<_EntityOption> _targetOptions() {
    return [
      ..._students.map(
        (e) => _EntityOption(
          type: _TargetType.student,
          id: e.id,
          label: 'Student: ${e.name}',
        ),
      ),
      ..._teachers.map(
        (e) => _EntityOption(
          type: _TargetType.teacher,
          id: e.id,
          label: 'Teacher: ${e.name}',
        ),
      ),
      ..._classes.map(
        (e) => _EntityOption(
          type: _TargetType.schoolClass,
          id: e.id,
          label: 'Class: ${e.name}',
        ),
      ),
    ];
  }

  String _targetTitle(_TargetType type, String id) {
    switch (type) {
      case _TargetType.student:
        final item = _students.where((e) => e.id == id).firstOrNull;
        return item == null ? 'Student' : 'Student: ${item.name}';
      case _TargetType.teacher:
        final item = _teachers.where((e) => e.id == id).firstOrNull;
        return item == null ? 'Teacher' : 'Teacher: ${item.name}';
      case _TargetType.schoolClass:
        final item = _classes.where((e) => e.id == id).firstOrNull;
        return item == null ? 'Class' : 'Class: ${item.name}';
    }
  }

  String _teacherName(String teacherId) {
    final item = _teachers.where((e) => e.id == teacherId).firstOrNull;
    return item?.name ?? 'Teacher';
  }

  List<_ExamItem> _parseExamItems(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) {
      final data = Map<String, dynamic>.from(item as Map);
      return _ExamItem(
        id: (data['id'] ?? '').toString(),
        title: (data['title'] ?? '').toString(),
        subject: (data['subject'] ?? '').toString(),
        date: (data['date'] ?? '').toString(),
        targetType: _targetTypeFromString(
          (data['targetType'] ?? '').toString(),
        ),
        targetId: (data['targetId'] ?? '').toString(),
      );
    }).toList();
  }

  List<_FeeItem> _parseFeeItems(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) {
      final data = Map<String, dynamic>.from(item as Map);
      return _FeeItem(
        id: (data['id'] ?? '').toString(),
        title: (data['title'] ?? '').toString(),
        amount: (data['amount'] ?? '').toString(),
        dueDate: (data['dueDate'] ?? '').toString(),
        targetType: _targetTypeFromString(
          (data['targetType'] ?? '').toString(),
        ),
        targetId: (data['targetId'] ?? '').toString(),
        paid: data['paid'] == true,
      );
    }).toList();
  }

  List<_LibraryItem> _parseLibraryItems(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) {
      final data = Map<String, dynamic>.from(item as Map);
      return _LibraryItem(
        id: (data['id'] ?? '').toString(),
        bookName: (data['bookName'] ?? '').toString(),
        dueDate: (data['dueDate'] ?? '').toString(),
        targetType: _targetTypeFromString(
          (data['targetType'] ?? '').toString(),
        ),
        targetId: (data['targetId'] ?? '').toString(),
        returned: data['returned'] == true,
      );
    }).toList();
  }

  List<_TimetableItem> _parseTimetableItems(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) {
      final data = Map<String, dynamic>.from(item as Map);
      return _TimetableItem(
        id: (data['id'] ?? '').toString(),
        day: (data['day'] ?? '').toString(),
        time: (data['time'] ?? '').toString(),
        subject: (data['subject'] ?? '').toString(),
        teacherId: (data['teacherId'] ?? '').toString(),
        classId: (data['classId'] ?? '').toString(),
      );
    }).toList();
  }

  List<_TransportItem> _parseTransportItems(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) {
      final data = Map<String, dynamic>.from(item as Map);
      return _TransportItem(
        id: (data['id'] ?? '').toString(),
        routeName: (data['routeName'] ?? '').toString(),
        vehicleNo: (data['vehicleNo'] ?? '').toString(),
        driver: (data['driver'] ?? '').toString(),
        targetType: _targetTypeFromString(
          (data['targetType'] ?? '').toString(),
        ),
        targetId: (data['targetId'] ?? '').toString(),
      );
    }).toList();
  }

  List<_NotificationItem> _parseNotificationItems(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) {
      final data = Map<String, dynamic>.from(item as Map);
      return _NotificationItem(
        id: (data['id'] ?? '').toString(),
        title: (data['title'] ?? '').toString(),
        message: (data['message'] ?? '').toString(),
        date: (data['date'] ?? '').toString(),
        targetType: _targetTypeFromString(
          (data['targetType'] ?? '').toString(),
        ),
        targetId: (data['targetId'] ?? '').toString(),
      );
    }).toList();
  }

  _TargetType _targetTypeFromString(String value) {
    switch (value) {
      case 'teacher':
        return _TargetType.teacher;
      case 'schoolClass':
        return _TargetType.schoolClass;
      case 'student':
      default:
        return _TargetType.student;
    }
  }

  String _targetTypeToString(_TargetType type) {
    switch (type) {
      case _TargetType.student:
        return 'student';
      case _TargetType.teacher:
        return 'teacher';
      case _TargetType.schoolClass:
        return 'schoolClass';
    }
  }

  Map<String, dynamic> _modulesPayload() {
    return {
      'exams': _examItems
          .map(
            (e) => {
              'id': e.id,
              'title': e.title,
              'subject': e.subject,
              'date': e.date,
              'targetType': _targetTypeToString(e.targetType),
              'targetId': e.targetId,
            },
          )
          .toList(),
      'fees': _feeItems
          .map(
            (e) => {
              'id': e.id,
              'title': e.title,
              'amount': e.amount,
              'dueDate': e.dueDate,
              'targetType': _targetTypeToString(e.targetType),
              'targetId': e.targetId,
              'paid': e.paid,
            },
          )
          .toList(),
      'library': _libraryItems
          .map(
            (e) => {
              'id': e.id,
              'bookName': e.bookName,
              'dueDate': e.dueDate,
              'targetType': _targetTypeToString(e.targetType),
              'targetId': e.targetId,
              'returned': e.returned,
            },
          )
          .toList(),
      'timetable': _timetableItems
          .map(
            (e) => {
              'id': e.id,
              'day': e.day,
              'time': e.time,
              'subject': e.subject,
              'teacherId': e.teacherId,
              'classId': e.classId,
            },
          )
          .toList(),
      'transport': _transportItems
          .map(
            (e) => {
              'id': e.id,
              'routeName': e.routeName,
              'vehicleNo': e.vehicleNo,
              'driver': e.driver,
              'targetType': _targetTypeToString(e.targetType),
              'targetId': e.targetId,
            },
          )
          .toList(),
      'notifications': _notificationItems
          .map(
            (e) => {
              'id': e.id,
              'title': e.title,
              'message': e.message,
              'date': e.date,
              'targetType': _targetTypeToString(e.targetType),
              'targetId': e.targetId,
            },
          )
          .toList(),
    };
  }

  Future<void> _persistModules() async {
    if (_isLocalMode) {
      return;
    }
    final uid = _requireUid();
    if (uid == null) {
      return;
    }
    try {
      await _service.saveModules(uid: uid, modules: _modulesPayload());
    } catch (error) {
      _activateLocalMode(error);
      _showError('Cloud sync failed. Module changes are local only.');
    }
  }

  Widget _buildStudentsPage(double width) {
    final students = _filteredStudents;
    final role = _auth.role;
    final isAdmin = role == AppRole.admin;
    final canViewPhone = role == AppRole.admin || role == AppRole.teacher;
    return LayoutBuilder(
      builder: (context, constraints) {
        final useScrollLayout = constraints.maxHeight < 540;
        final list = students.isEmpty
            ? const _EmptyState(message: 'No students found.')
            : ListView.separated(
                shrinkWrap: useScrollLayout,
                physics: useScrollLayout
                    ? const NeverScrollableScrollPhysics()
                    : null,
                itemCount: students.length,
                separatorBuilder: (_, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final student = students[index];
                  return _buildStudentCard(
                    student: student,
                    showFullDetails: isAdmin,
                    showPhone: canViewPhone,
                  );
                },
              );

        if (useScrollLayout) {
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildSectionHeader(
                  title: 'Students',
                  actionLabel: 'Add Student',
                  onAction: _openCreateStudentDialog,
                  isCompact: true,
                ),
                const SizedBox(height: 10),
                _buildStudentControls(),
                const SizedBox(height: 10),
                _buildAiInsightPanel(
                  moduleName: 'Students',
                  insight: _studentInsight(students),
                ),
                const SizedBox(height: 10),
                list,
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildSectionHeader(
              title: 'Students',
              actionLabel: 'Add Student',
              onAction: _openCreateStudentDialog,
              isCompact: width < 700,
            ),
            const SizedBox(height: 10),
            _buildStudentControls(),
            const SizedBox(height: 10),
            _buildAiInsightPanel(
              moduleName: 'Students',
              insight: _studentInsight(students),
            ),
            const SizedBox(height: 10),
            Expanded(child: list),
          ],
        );
      },
    );
  }

  Widget _buildStudentCard({
    required SchoolStudent student,
    required bool showFullDetails,
    required bool showPhone,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _studentPhotoAvatar(student),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Age ${student.age} • Grade ${student.grade}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Roll ${student.rollNumber}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (showPhone && student.phoneNumber.trim().isNotEmpty)
                    Text(
                      'Phone: ${student.phoneNumber.trim()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (showFullDetails) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Parent: ${student.parentName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Student ID: ${student.studentIdentityNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Parent ID: ${student.parentIdentityNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (student.notes.trim().isNotEmpty)
                      Text(
                        'Notes: ${student.notes.trim()}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ],
              ),
            ),
            _ActionButtons(
              onEdit: () => _openEditStudentDialog(student),
              onDelete: () => _deleteStudent(student),
            ),
          ],
        ),
      ),
    );
  }

  Widget _studentPhotoAvatar(SchoolStudent student) {
    final url = student.photoUrl.trim();
    final isNetwork = url.startsWith('http://') || url.startsWith('https://');
    final normalizedPath = url.startsWith('file://')
        ? Uri.parse(url).toFilePath()
        : url;
    return Container(
      width: 72,
      height: 84,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B4DB8), Color(0xFF1591E6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black, width: 1.8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: url.isEmpty
            ? Icon(
                Icons.school_rounded,
                color: Colors.white.withValues(alpha: 0.95),
                size: 36,
              )
            : isNetwork
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.person_rounded,
                  color: Colors.white.withValues(alpha: 0.95),
                  size: 36,
                ),
              )
            : Image.file(
                File(normalizedPath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.person_rounded,
                  color: Colors.white.withValues(alpha: 0.95),
                  size: 36,
                ),
              ),
      ),
    );
  }

  Widget _buildStudentControls() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: Responsive.controlWidth(context, preferred: 320),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              labelText: 'Search students',
              hintText: 'Name, roll, or grade',
            ),
            onChanged: (value) {
              setState(() => _studentSearch = value);
            },
          ),
        ),
        SizedBox(
          width: Responsive.controlWidth(context, preferred: 220),
          child: DropdownButtonFormField<_StudentSort>(
            initialValue: _studentSort,
            decoration: const InputDecoration(labelText: 'Sort by'),
            items: const [
              DropdownMenuItem(
                value: _StudentSort.nameAsc,
                child: Text('Name (A-Z)'),
              ),
              DropdownMenuItem(
                value: _StudentSort.nameDesc,
                child: Text('Name (Z-A)'),
              ),
              DropdownMenuItem(
                value: _StudentSort.gradeAsc,
                child: Text('Grade (Low-High)'),
              ),
              DropdownMenuItem(
                value: _StudentSort.gradeDesc,
                child: Text('Grade (High-Low)'),
              ),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() => _studentSort = value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTeachersPage(double width) {
    final teachers = _filteredTeachers;
    final isAdmin = _auth.role == AppRole.admin;
    return LayoutBuilder(
      builder: (context, constraints) {
        final useScrollLayout = constraints.maxHeight < 540;
        final list = teachers.isEmpty
            ? const _EmptyState(message: 'No teachers found.')
            : ListView.separated(
                shrinkWrap: useScrollLayout,
                physics: useScrollLayout
                    ? const NeverScrollableScrollPhysics()
                    : null,
                itemCount: teachers.length,
                separatorBuilder: (_, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final teacher = teachers[index];
                  return _buildTeacherCard(
                    teacher: teacher,
                    showFullDetails: isAdmin,
                  );
                },
              );

        if (useScrollLayout) {
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildSectionHeader(
                  title: 'Teachers',
                  actionLabel: 'Add Teacher',
                  onAction: _openCreateTeacherDialog,
                  isCompact: true,
                ),
                const SizedBox(height: 10),
                _buildTeacherControls(),
                const SizedBox(height: 10),
                _buildAiInsightPanel(
                  moduleName: 'Teachers',
                  insight: _teacherInsight(teachers),
                ),
                const SizedBox(height: 10),
                list,
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildSectionHeader(
              title: 'Teachers',
              actionLabel: 'Add Teacher',
              onAction: _openCreateTeacherDialog,
              isCompact: width < 700,
            ),
            const SizedBox(height: 10),
            _buildTeacherControls(),
            const SizedBox(height: 10),
            _buildAiInsightPanel(
              moduleName: 'Teachers',
              insight: _teacherInsight(teachers),
            ),
            const SizedBox(height: 10),
            Expanded(child: list),
          ],
        );
      },
    );
  }

  Widget _buildTeacherCard({
    required SchoolTeacher teacher,
    required bool showFullDetails,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(teacher.name.characters.first)),
        title: Text(teacher.name),
        subtitle: Text(
          showFullDetails
              ? _teacherAdminSummary(teacher)
              : 'Subject: ${teacher.subject}',
          maxLines: showFullDetails ? 5 : 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _ActionButtons(
          onEdit: () => _openEditTeacherDialog(teacher),
          onDelete: () => _deleteTeacher(teacher),
        ),
      ),
    );
  }

  String _teacherAdminSummary(SchoolTeacher teacher) {
    final lines = <String>[
      'Subject: ${teacher.subject}',
      'Email: ${teacher.email}',
    ];
    if (teacher.age.trim().isNotEmpty) {
      lines.add('Age: ${teacher.age.trim()}');
    }
    if (teacher.qualifications.trim().isNotEmpty) {
      lines.add('Qualifications: ${teacher.qualifications.trim()}');
    }
    if (teacher.phoneNumber.trim().isNotEmpty) {
      lines.add('Phone: ${teacher.phoneNumber.trim()}');
    }
    if (teacher.identityNumber.trim().isNotEmpty) {
      lines.add('Identity: ${teacher.identityNumber.trim()}');
    }
    if (teacher.address.trim().isNotEmpty) {
      lines.add('Address: ${teacher.address.trim()}');
    }
    if (teacher.notes.trim().isNotEmpty) {
      lines.add('Notes: ${teacher.notes.trim()}');
    }
    return lines.join('\n');
  }

  Widget _buildTeacherControls() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: Responsive.controlWidth(context, preferred: 320),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              labelText: 'Search teachers',
              hintText: 'Name, subject, or email',
            ),
            onChanged: (value) {
              setState(() => _teacherSearch = value);
            },
          ),
        ),
        SizedBox(
          width: Responsive.controlWidth(context, preferred: 220),
          child: DropdownButtonFormField<_TeacherSort>(
            initialValue: _teacherSort,
            decoration: const InputDecoration(labelText: 'Sort by'),
            items: const [
              DropdownMenuItem(
                value: _TeacherSort.nameAsc,
                child: Text('Name (A-Z)'),
              ),
              DropdownMenuItem(
                value: _TeacherSort.nameDesc,
                child: Text('Name (Z-A)'),
              ),
              DropdownMenuItem(
                value: _TeacherSort.subjectAsc,
                child: Text('Subject (A-Z)'),
              ),
              DropdownMenuItem(
                value: _TeacherSort.subjectDesc,
                child: Text('Subject (Z-A)'),
              ),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() => _teacherSort = value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildClassesPage(double width) {
    final insight = _classInsight(_classes);
    return LayoutBuilder(
      builder: (context, constraints) {
        final useScrollLayout = constraints.maxHeight < 560;
        Widget classesList;
        if (_classes.isEmpty) {
          classesList = const _EmptyState(message: 'No classes created yet.');
        } else {
          final columns = constraints.maxWidth >= 980 ? 2 : 1;
          if (columns == 1) {
            classesList = ListView.separated(
              shrinkWrap: useScrollLayout,
              physics: useScrollLayout
                  ? const NeverScrollableScrollPhysics()
                  : null,
              itemCount: _classes.length,
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _buildClassCard(_classes[index]),
            );
          } else {
            classesList = GridView.builder(
              shrinkWrap: useScrollLayout,
              physics: useScrollLayout
                  ? const NeverScrollableScrollPhysics()
                  : null,
              itemCount: _classes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.25,
              ),
              itemBuilder: (context, index) => _buildClassCard(_classes[index]),
            );
          }
        }

        if (useScrollLayout) {
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildSectionHeader(
                  title: 'Classes',
                  actionLabel: 'Create Class',
                  onAction: _openCreateClassDialog,
                  isCompact: true,
                ),
                const SizedBox(height: 10),
                _buildAiInsightPanel(moduleName: 'Classes', insight: insight),
                const SizedBox(height: 10),
                classesList,
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildSectionHeader(
              title: 'Classes',
              actionLabel: 'Create Class',
              onAction: _openCreateClassDialog,
              isCompact: width < 700,
            ),
            const SizedBox(height: 10),
            _buildAiInsightPanel(moduleName: 'Classes', insight: insight),
            const SizedBox(height: 10),
            Expanded(child: classesList),
          ],
        );
      },
    );
  }

  Widget _buildAiInsightPanel({
    required String moduleName,
    required _AiInsight insight,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Insights • $moduleName',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              insight.headline,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            ...insight.points.map(
              (point) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $point'),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: insight.actions
                  .map(
                    (action) => ActionChip(
                      avatar: const Icon(
                        Icons.psychology_alt_rounded,
                        size: 16,
                      ),
                      label: Text(action.label),
                      onPressed: () => _openAiChatForModule(
                        module: moduleName,
                        prompt: action.prompt,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _openAiChatForModule({required String module, required String prompt}) {
    Get.toNamed(
      RouteConstants.chatbot,
      arguments: <String, String>{'module': module, 'prompt': prompt},
    );
  }

  _AiInsight _studentInsight(List<SchoolStudent> students) {
    if (students.isEmpty) {
      return const _AiInsight(
        headline: 'No student records yet.',
        points: ['Add students to get AI trends and planning support.'],
        actions: [
          _AiPromptAction(
            label: 'Setup Guide',
            prompt: 'Give me a quick setup checklist for student records.',
          ),
        ],
      );
    }

    final gradeCounts = <String, int>{};
    final rollSet = <String>{};
    var duplicateRolls = 0;
    for (final student in students) {
      gradeCounts[student.grade] = (gradeCounts[student.grade] ?? 0) + 1;
      final key = '${student.grade}:${student.rollNumber}'.toLowerCase();
      if (!rollSet.add(key)) {
        duplicateRolls++;
      }
    }

    final topGrade = gradeCounts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    return _AiInsight(
      headline:
          'Student distribution shows highest concentration in Grade $topGrade.',
      points: [
        'Total students: ${students.length}',
        'Grade $topGrade has ${gradeCounts[topGrade]} students.',
        if (duplicateRolls > 0)
          'Potential duplicate roll numbers found: $duplicateRolls',
      ],
      actions: const [
        _AiPromptAction(
          label: 'Retention Risks',
          prompt:
              'Analyze student retention risks using attendance and results patterns.',
        ),
        _AiPromptAction(
          label: 'Intervention Plan',
          prompt:
              'Create a short intervention plan for low-performing students by grade.',
        ),
      ],
    );
  }

  _AiInsight _teacherInsight(List<SchoolTeacher> teachers) {
    if (teachers.isEmpty) {
      return const _AiInsight(
        headline: 'No teacher records yet.',
        points: ['Add teachers to get AI staffing and subject-load insights.'],
        actions: [
          _AiPromptAction(
            label: 'Staffing Guide',
            prompt: 'Give me a teacher staffing setup guide for this school.',
          ),
        ],
      );
    }

    final subjectCounts = <String, int>{};
    var invalidEmailCount = 0;
    for (final teacher in teachers) {
      subjectCounts[teacher.subject] =
          (subjectCounts[teacher.subject] ?? 0) + 1;
      if (!teacher.email.contains('@')) {
        invalidEmailCount++;
      }
    }
    final topSubject = subjectCounts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    return _AiInsight(
      headline: 'Teacher allocation is strongest in $topSubject.',
      points: [
        'Total teachers: ${teachers.length}',
        '$topSubject coverage: ${subjectCounts[topSubject]} teachers',
        if (invalidEmailCount > 0)
          'Teacher contacts needing verification: $invalidEmailCount',
      ],
      actions: const [
        _AiPromptAction(
          label: 'Workload Balance',
          prompt:
              'Suggest a workload balancing strategy across teachers and subjects.',
        ),
        _AiPromptAction(
          label: 'Development Plan',
          prompt:
              'Create a teacher development plan based on subject coverage gaps.',
        ),
      ],
    );
  }

  _AiInsight _classInsight(List<SchoolClass> classes) {
    if (classes.isEmpty) {
      return const _AiInsight(
        headline: 'No classes created yet.',
        points: [
          'Create classes to unlock AI attendance and staffing insights.',
        ],
        actions: [
          _AiPromptAction(
            label: 'Class Setup',
            prompt: 'Give me a best-practice class setup checklist.',
          ),
        ],
      );
    }

    final totalStudents = classes.fold<int>(
      0,
      (sum, schoolClass) => sum + schoolClass.studentIds.length,
    );
    final avgSize = totalStudents / classes.length;
    final unassigned = classes.where((c) => c.teacherId == null).length;
    final lowAttendance = classes.where((c) {
      if (c.attendance.isEmpty) return false;
      final present = c.attendance.values.where((v) => v).length;
      final rate = present / c.attendance.length;
      return rate < 0.75;
    }).length;

    return _AiInsight(
      headline:
          'Class operations show average size ${avgSize.toStringAsFixed(1)}.',
      points: [
        'Total classes: ${classes.length}',
        'Classes without assigned teacher: $unassigned',
        'Low-attendance classes (<75%): $lowAttendance',
      ],
      actions: const [
        _AiPromptAction(
          label: 'Attendance Recovery',
          prompt:
              'Create an attendance recovery strategy for low-attendance classes.',
        ),
        _AiPromptAction(
          label: 'Class Optimization',
          prompt:
              'Suggest class-size and teacher-assignment optimization actions.',
        ),
      ],
    );
  }

  Widget _buildClassCard(SchoolClass schoolClass) {
    final teacher = _teachers.where((teacher) {
      return teacher.id == schoolClass.teacherId;
    }).firstOrNull;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      schoolClass.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: () => _openEditClassDialog(schoolClass),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: () => _deleteClass(schoolClass),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
              Text('Teacher: ${teacher?.name ?? 'Not assigned'}'),
              const SizedBox(height: 8),
              Text('Attendance', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              if (schoolClass.studentIds.isEmpty)
                const Text('No students assigned. Edit class to add students.')
              else
                ...schoolClass.studentIds.map((studentId) {
                  final student = _students.where((item) {
                    return item.id == studentId;
                  }).firstOrNull;
                  if (student == null) {
                    return const SizedBox.shrink();
                  }
                  final isPresent = schoolClass.attendance[student.id] ?? false;
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(student.name),
                    subtitle: Text('Roll: ${student.rollNumber}'),
                    value: isPresent,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      _markAttendance(
                        schoolClass: schoolClass,
                        studentId: student.id,
                        isPresent: value,
                      );
                    },
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String actionLabel,
    required VoidCallback onAction,
    required bool isCompact,
  }) {
    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add_rounded),
            label: Text(actionLabel),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 380;
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(actionLabel),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<_EntityOption?> _pickTarget({
    required BuildContext dialogContext,
    _EntityOption? current,
  }) async {
    final options = _targetOptions();
    if (options.isEmpty) {
      _showError('Add students, teachers, or classes first.');
      return null;
    }
    return showModalBottomSheet<_EntityOption>(
      context: dialogContext,
      builder: (context) => SafeArea(
        child: ListView(
          children: options.map((option) {
            final selected =
                current?.id == option.id && current?.type == option.type;
            return ListTile(
              title: Text(option.label),
              trailing: selected ? const Icon(Icons.check_rounded) : null,
              onTap: () => Navigator.pop(context, option),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _responsiveDialogContent({
    required Widget child,
    double preferredWidth = 560,
  }) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final keyboardInset = media.viewInsets.bottom;

    final outerHorizontalPadding = screenWidth < 600 ? 16.0 : 32.0;
    final targetMaxWidth = screenWidth >= 1280
        ? 860.0
        : screenWidth >= 900
        ? 760.0
        : screenWidth >= 700
        ? 640.0
        : 560.0;
    final dialogWidth = (screenWidth - (outerHorizontalPadding * 2)).clamp(
      280.0,
      targetMaxWidth,
    );
    final responsivePreferred = Responsive.controlWidth(
      context,
      preferred: preferredWidth,
    );
    final maxWidth = dialogWidth < responsivePreferred
        ? dialogWidth
        : responsivePreferred;

    final availableHeight = (media.size.height - keyboardInset - 120).clamp(
      240.0,
      1200.0,
    );
    final heightFactor = screenWidth < 600 ? 0.72 : 0.78;
    final maxHeight = (availableHeight * heightFactor).clamp(240.0, 720.0);

    return SizedBox(
      width: maxWidth,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: SingleChildScrollView(
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }

  List<Widget> _dialogFieldSpacing(List<Widget> fields, {double gap = 14}) {
    if (fields.isEmpty) return const [];
    final widgets = <Widget>[];
    for (var i = 0; i < fields.length; i++) {
      widgets.add(fields[i]);
      if (i < fields.length - 1) {
        widgets.add(SizedBox(height: gap));
      }
    }
    return widgets;
  }

  Future<void> _openAddExamDialog() async {
    final titleController = TextEditingController();
    final subjectController = TextEditingController();
    final dateController = TextEditingController();
    _EntityOption? selected;
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
              children: _dialogFieldSpacing([
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
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await _pickTarget(
                      dialogContext: dialogContext,
                      current: selected,
                    );
                    if (picked != null) {
                      setDialog(() => selected = picked);
                    }
                  },
                  icon: const Icon(Icons.person_pin_rounded),
                  label: Text(selected?.label ?? 'Select Target'),
                ),
              ]),
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
                    selected == null) {
                  _showError('Fill all exam fields.');
                  return;
                }
                _updateModules(() {
                  _examItems = [
                    ..._examItems,
                    _ExamItem(
                      id: _nextLocalId(),
                      title: titleController.text.trim(),
                      subject: subjectController.text.trim(),
                      date: dateController.text.trim(),
                      targetType: selected!.type,
                      targetId: selected!.id,
                    ),
                  ];
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    _disposeControllersLater([
      titleController,
      subjectController,
      dateController,
    ]);
  }

  Future<void> _openAddFeeDialog() async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final dueController = TextEditingController();
    _EntityOption? selected;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          actionsOverflowDirection: VerticalDirection.down,
          actionsOverflowButtonSpacing: 8,
          title: const Text('Add Fee Record'),
          content: _responsiveDialogContent(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _dialogFieldSpacing([
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Fee Title'),
                ),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                TextField(
                  controller: dueController,
                  decoration: const InputDecoration(labelText: 'Due Date'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await _pickTarget(
                      dialogContext: dialogContext,
                      current: selected,
                    );
                    if (picked != null) {
                      setDialog(() => selected = picked);
                    }
                  },
                  icon: const Icon(Icons.person_pin_rounded),
                  label: Text(selected?.label ?? 'Select Target'),
                ),
              ]),
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
                    amountController.text.trim().isEmpty ||
                    dueController.text.trim().isEmpty ||
                    selected == null) {
                  _showError('Fill all fee fields.');
                  return;
                }
                _updateModules(() {
                  _feeItems = [
                    ..._feeItems,
                    _FeeItem(
                      id: _nextLocalId(),
                      title: titleController.text.trim(),
                      amount: amountController.text.trim(),
                      dueDate: dueController.text.trim(),
                      targetType: selected!.type,
                      targetId: selected!.id,
                      paid: false,
                    ),
                  ];
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    _disposeControllersLater([
      titleController,
      amountController,
      dueController,
    ]);
  }

  Future<void> _openAddLibraryDialog() async {
    final bookController = TextEditingController();
    final dueController = TextEditingController();
    _EntityOption? selected;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          actionsOverflowDirection: VerticalDirection.down,
          actionsOverflowButtonSpacing: 8,
          title: const Text('Issue Library Book'),
          content: _responsiveDialogContent(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _dialogFieldSpacing([
                TextField(
                  controller: bookController,
                  decoration: const InputDecoration(labelText: 'Book Name'),
                ),
                TextField(
                  controller: dueController,
                  decoration: const InputDecoration(labelText: 'Due Date'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await _pickTarget(
                      dialogContext: dialogContext,
                      current: selected,
                    );
                    if (picked != null) {
                      setDialog(() => selected = picked);
                    }
                  },
                  icon: const Icon(Icons.person_pin_rounded),
                  label: Text(selected?.label ?? 'Select Target'),
                ),
              ]),
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
                    selected == null) {
                  _showError('Fill all library fields.');
                  return;
                }
                _updateModules(() {
                  _libraryItems = [
                    ..._libraryItems,
                    _LibraryItem(
                      id: _nextLocalId(),
                      bookName: bookController.text.trim(),
                      dueDate: dueController.text.trim(),
                      targetType: selected!.type,
                      targetId: selected!.id,
                      returned: false,
                    ),
                  ];
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('Issue'),
            ),
          ],
        ),
      ),
    );
    _disposeControllersLater([bookController, dueController]);
  }

  Future<void> _openAddTimetableDialog() async {
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
              children: _dialogFieldSpacing([
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
                DropdownButtonFormField<String>(
                  initialValue: teacherId,
                  decoration: const InputDecoration(labelText: 'Teacher'),
                  items: _teachers
                      .map(
                        (e) =>
                            DropdownMenuItem(value: e.id, child: Text(e.name)),
                      )
                      .toList(),
                  onChanged: (v) => setDialog(() => teacherId = v),
                ),
                DropdownButtonFormField<String>(
                  initialValue: classId,
                  decoration: const InputDecoration(labelText: 'Class'),
                  items: _classes
                      .map(
                        (e) =>
                            DropdownMenuItem(value: e.id, child: Text(e.name)),
                      )
                      .toList(),
                  onChanged: (v) => setDialog(() => classId = v),
                ),
              ]),
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
                _updateModules(() {
                  _timetableItems = [
                    ..._timetableItems,
                    _TimetableItem(
                      id: _nextLocalId(),
                      day: dayController.text.trim(),
                      time: timeController.text.trim(),
                      subject: subjectController.text.trim(),
                      teacherId: teacherId!,
                      classId: classId!,
                    ),
                  ];
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    _disposeControllersLater([
      dayController,
      timeController,
      subjectController,
    ]);
  }

  Future<void> _openAddTransportDialog() async {
    final routeController = TextEditingController();
    final vehicleController = TextEditingController();
    final driverController = TextEditingController();
    _EntityOption? selected;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          actionsOverflowDirection: VerticalDirection.down,
          actionsOverflowButtonSpacing: 8,
          title: const Text('Add Transport Route'),
          content: _responsiveDialogContent(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _dialogFieldSpacing([
                TextField(
                  controller: routeController,
                  decoration: const InputDecoration(labelText: 'Route Name'),
                ),
                TextField(
                  controller: vehicleController,
                  decoration: const InputDecoration(labelText: 'Vehicle No'),
                ),
                TextField(
                  controller: driverController,
                  decoration: const InputDecoration(labelText: 'Driver Name'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await _pickTarget(
                      dialogContext: dialogContext,
                      current: selected,
                    );
                    if (picked != null) {
                      setDialog(() => selected = picked);
                    }
                  },
                  icon: const Icon(Icons.person_pin_rounded),
                  label: Text(selected?.label ?? 'Assign Target'),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (routeController.text.trim().isEmpty ||
                    vehicleController.text.trim().isEmpty ||
                    driverController.text.trim().isEmpty ||
                    selected == null) {
                  _showError('Fill all transport fields.');
                  return;
                }
                _updateModules(() {
                  _transportItems = [
                    ..._transportItems,
                    _TransportItem(
                      id: _nextLocalId(),
                      routeName: routeController.text.trim(),
                      vehicleNo: vehicleController.text.trim(),
                      driver: driverController.text.trim(),
                      targetType: selected!.type,
                      targetId: selected!.id,
                    ),
                  ];
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    _disposeControllersLater([
      routeController,
      vehicleController,
      driverController,
    ]);
  }

  Future<void> _openAddNotificationDialog() async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    final dateController = TextEditingController();
    _EntityOption? selected;
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
              children: _dialogFieldSpacing([
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
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await _pickTarget(
                      dialogContext: dialogContext,
                      current: selected,
                    );
                    if (picked != null) {
                      setDialog(() => selected = picked);
                    }
                  },
                  icon: const Icon(Icons.person_pin_rounded),
                  label: Text(selected?.label ?? 'Select Target'),
                ),
              ]),
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
                    selected == null) {
                  _showError('Fill all notification fields.');
                  return;
                }
                _updateModules(() {
                  _notificationItems = [
                    ..._notificationItems,
                    _NotificationItem(
                      id: _nextLocalId(),
                      title: titleController.text.trim(),
                      message: messageController.text.trim(),
                      date: dateController.text.trim(),
                      targetType: selected!.type,
                      targetId: selected!.id,
                    ),
                  ];
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
    _disposeControllersLater([
      titleController,
      messageController,
      dateController,
    ]);
  }

  Future<void> _openCreateStudentDialog() async {
    await _openStudentDialog();
  }

  Future<void> _openEditStudentDialog(SchoolStudent student) async {
    await _openStudentDialog(existing: student);
  }

  Future<void> _openStudentDialog({SchoolStudent? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final rollController = TextEditingController(
      text: existing?.rollNumber ?? '',
    );
    final gradeController = TextEditingController(text: existing?.grade ?? '');
    final ageController = TextEditingController(text: existing?.age ?? '');
    final phoneController = TextEditingController(
      text: existing?.phoneNumber ?? '',
    );
    final parentNameController = TextEditingController(
      text: existing?.parentName ?? '',
    );
    final parentIdController = TextEditingController(
      text: existing?.parentIdentityNumber ?? '',
    );
    final studentIdController = TextEditingController(
      text: existing?.studentIdentityNumber ?? '',
    );
    final photoController = TextEditingController(
      text: existing?.photoUrl ?? '',
    );
    final notesController = TextEditingController(text: existing?.notes ?? '');
    bool isUploadingPhoto = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          actionsOverflowDirection: VerticalDirection.down,
          actionsOverflowButtonSpacing: 8,
          title: Text(existing == null ? 'Add Student' : 'Edit Student'),
          content: _responsiveDialogContent(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _dialogFieldSpacing([
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: rollController,
                  decoration: const InputDecoration(labelText: 'Roll Number'),
                ),
                TextField(
                  controller: gradeController,
                  decoration: const InputDecoration(labelText: 'Grade'),
                ),
                TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Age'),
                ),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                ),
                TextField(
                  controller: parentNameController,
                  decoration: const InputDecoration(labelText: 'Parent Name'),
                ),
                TextField(
                  controller: parentIdController,
                  decoration: const InputDecoration(
                    labelText: 'Parent Identity Number',
                  ),
                ),
                TextField(
                  controller: studentIdController,
                  decoration: const InputDecoration(
                    labelText: 'Student Identity Number',
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: photoController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Student Photo',
                          hintText: 'Select image from device',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: isUploadingPhoto
                          ? null
                          : () async {
                              setDialogState(() => isUploadingPhoto = true);
                              final urlOrPath = await _pickStudentImage(
                                existingStudentId: existing?.id,
                              );
                              if (!mounted) {
                                return;
                              }
                              if (urlOrPath != null && urlOrPath.isNotEmpty) {
                                photoController.text = urlOrPath;
                              }
                              setDialogState(() => isUploadingPhoto = false);
                            },
                      icon: isUploadingPhoto
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_rounded),
                      label: Text(_isLocalMode ? 'Select' : 'Upload'),
                    ),
                  ],
                ),
                TextField(
                  controller: notesController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final roll = rollController.text.trim();
                final grade = gradeController.text.trim();
                final age = ageController.text.trim();
                final phoneNumber = _normalizePhone(phoneController.text);
                final parentName = parentNameController.text.trim();
                final parentId = parentIdController.text.trim();
                final studentId = studentIdController.text.trim();
                final photoUrl = photoController.text.trim();
                final notes = notesController.text.trim();
                if (name.isEmpty ||
                    roll.isEmpty ||
                    grade.isEmpty ||
                    age.isEmpty ||
                    phoneNumber.isEmpty ||
                    parentName.isEmpty ||
                    parentId.isEmpty ||
                    studentId.isEmpty) {
                  _showError('Please fill all student fields.');
                  return;
                }
                if (!_isValidPhoneNumber(phoneNumber)) {
                  _showError(
                    'Enter a valid student phone number (10-15 digits, optional +).',
                  );
                  return;
                }

                Navigator.pop(dialogContext);
                await _saveStudent(
                  existing: existing,
                  name: name,
                  rollNumber: roll,
                  grade: grade,
                  age: age,
                  phoneNumber: phoneNumber,
                  parentName: parentName,
                  parentIdentityNumber: parentId,
                  studentIdentityNumber: studentId,
                  photoUrl: photoUrl,
                  notes: notes,
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    _disposeControllersLater([
      nameController,
      rollController,
      gradeController,
      ageController,
      phoneController,
      parentNameController,
      parentIdController,
      studentIdController,
      photoController,
      notesController,
    ]);
  }

  Future<String?> _pickStudentImage({String? existingStudentId}) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1400,
      );
      if (picked == null) {
        return null;
      }

      if (_isLocalMode) {
        return picked.path;
      }

      final uid = _requireUid();
      if (uid == null) {
        return null;
      }
      final objectName = _studentPhotoObjectName(
        existingStudentId: existingStudentId,
        originalName: picked.name,
      );
      final ref = StorageService.instance.ref().child(
        'users/$uid/studentPhotos/$objectName',
      );
      await ref.putFile(File(picked.path));
      final downloadUrl = await ref.getDownloadURL();
      _showMessage('Student photo uploaded.');
      return downloadUrl;
    } catch (error) {
      _showError('Could not upload image. ${_toFriendlySyncError("$error")}');
      return null;
    }
  }

  String _studentPhotoObjectName({
    String? existingStudentId,
    required String originalName,
  }) {
    final safeName = originalName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final baseId = existingStudentId ?? _nextLocalId();
    return '${baseId}_${DateTime.now().millisecondsSinceEpoch}_$safeName';
  }

  String _normalizePhone(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final hasPlus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    return hasPlus ? '+$digits' : digits;
  }

  bool _isValidPhoneNumber(String value) {
    return RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value);
  }

  Future<void> _saveStudent({
    required SchoolStudent? existing,
    required String name,
    required String rollNumber,
    required String grade,
    required String age,
    required String phoneNumber,
    required String parentName,
    required String parentIdentityNumber,
    required String studentIdentityNumber,
    required String photoUrl,
    required String notes,
  }) async {
    if (_isLocalMode) {
      _saveStudentLocal(
        existing: existing,
        name: name,
        rollNumber: rollNumber,
        grade: grade,
        age: age,
        phoneNumber: phoneNumber,
        parentName: parentName,
        parentIdentityNumber: parentIdentityNumber,
        studentIdentityNumber: studentIdentityNumber,
        photoUrl: photoUrl,
        notes: notes,
      );
      _showMessage('Student saved locally.');
      return;
    }

    final uid = _requireUid();
    if (uid == null) {
      return;
    }

    try {
      if (existing == null) {
        await _service.createStudent(
          uid: uid,
          name: name,
          rollNumber: rollNumber,
          grade: grade,
          age: age,
          phoneNumber: phoneNumber,
          parentName: parentName,
          parentIdentityNumber: parentIdentityNumber,
          studentIdentityNumber: studentIdentityNumber,
          photoUrl: photoUrl,
          notes: notes,
        );
      } else {
        await _service.updateStudent(
          uid: uid,
          id: existing.id,
          name: name,
          rollNumber: rollNumber,
          grade: grade,
          age: age,
          phoneNumber: phoneNumber,
          parentName: parentName,
          parentIdentityNumber: parentIdentityNumber,
          studentIdentityNumber: studentIdentityNumber,
          photoUrl: photoUrl,
          notes: notes,
        );
      }
      _showMessage('Student saved.');
    } catch (error) {
      _activateLocalMode(error);
      _saveStudentLocal(
        existing: existing,
        name: name,
        rollNumber: rollNumber,
        grade: grade,
        age: age,
        phoneNumber: phoneNumber,
        parentName: parentName,
        parentIdentityNumber: parentIdentityNumber,
        studentIdentityNumber: studentIdentityNumber,
        photoUrl: photoUrl,
        notes: notes,
      );
      _showMessage('Cloud sync failed. Student saved locally.');
    }
  }

  Future<void> _openCreateTeacherDialog() async {
    await _openTeacherDialog();
  }

  Future<void> _openEditTeacherDialog(SchoolTeacher teacher) async {
    await _openTeacherDialog(existing: teacher);
  }

  Future<void> _openTeacherDialog({SchoolTeacher? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final subjectController = TextEditingController(
      text: existing?.subject ?? '',
    );
    final emailController = TextEditingController(text: existing?.email ?? '');
    final ageController = TextEditingController(text: existing?.age ?? '');
    final qualificationController = TextEditingController(
      text: existing?.qualifications ?? '',
    );
    final phoneController = TextEditingController(
      text: existing?.phoneNumber ?? '',
    );
    final identityController = TextEditingController(
      text: existing?.identityNumber ?? '',
    );
    final addressController = TextEditingController(
      text: existing?.address ?? '',
    );
    final notesController = TextEditingController(text: existing?.notes ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        actionsOverflowDirection: VerticalDirection.down,
        actionsOverflowButtonSpacing: 8,
        title: Text(existing == null ? 'Add Teacher' : 'Edit Teacher'),
        content: _responsiveDialogContent(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _dialogFieldSpacing([
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: 'Subject'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age'),
              ),
              TextField(
                controller: qualificationController,
                decoration: const InputDecoration(labelText: 'Qualifications'),
              ),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              TextField(
                controller: identityController,
                decoration: const InputDecoration(labelText: 'Identity Number'),
              ),
              TextField(
                controller: addressController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextField(
                controller: notesController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final subject = subjectController.text.trim();
              final email = emailController.text.trim();
              final age = ageController.text.trim();
              final qualifications = qualificationController.text.trim();
              final phoneNumber = _normalizePhone(phoneController.text);
              final identityNumber = identityController.text.trim();
              final address = addressController.text.trim();
              final notes = notesController.text.trim();
              if (name.isEmpty || subject.isEmpty || email.isEmpty) {
                _showError('Please fill all teacher fields.');
                return;
              }
              if (phoneNumber.isNotEmpty && !_isValidPhoneNumber(phoneNumber)) {
                _showError(
                  'Enter a valid teacher phone number (10-15 digits, optional +).',
                );
                return;
              }

              Navigator.pop(dialogContext);
              await _saveTeacher(
                existing: existing,
                name: name,
                subject: subject,
                email: email,
                age: age,
                qualifications: qualifications,
                phoneNumber: phoneNumber,
                identityNumber: identityNumber,
                address: address,
                notes: notes,
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    _disposeControllersLater([
      nameController,
      subjectController,
      emailController,
      ageController,
      qualificationController,
      phoneController,
      identityController,
      addressController,
      notesController,
    ]);
  }

  Future<void> _saveTeacher({
    required SchoolTeacher? existing,
    required String name,
    required String subject,
    required String email,
    required String age,
    required String qualifications,
    required String phoneNumber,
    required String identityNumber,
    required String address,
    required String notes,
  }) async {
    if (_isLocalMode) {
      _saveTeacherLocal(
        existing: existing,
        name: name,
        subject: subject,
        email: email,
        age: age,
        qualifications: qualifications,
        phoneNumber: phoneNumber,
        identityNumber: identityNumber,
        address: address,
        notes: notes,
      );
      _showMessage('Teacher saved locally.');
      return;
    }

    final uid = _requireUid();
    if (uid == null) {
      return;
    }

    try {
      if (existing == null) {
        await _service.createTeacher(
          uid: uid,
          name: name,
          subject: subject,
          email: email,
          age: age,
          qualifications: qualifications,
          phoneNumber: phoneNumber,
          identityNumber: identityNumber,
          address: address,
          notes: notes,
        );
      } else {
        await _service.updateTeacher(
          uid: uid,
          id: existing.id,
          name: name,
          subject: subject,
          email: email,
          age: age,
          qualifications: qualifications,
          phoneNumber: phoneNumber,
          identityNumber: identityNumber,
          address: address,
          notes: notes,
        );
      }
      _showMessage('Teacher saved.');
    } catch (error) {
      _activateLocalMode(error);
      _saveTeacherLocal(
        existing: existing,
        name: name,
        subject: subject,
        email: email,
        age: age,
        qualifications: qualifications,
        phoneNumber: phoneNumber,
        identityNumber: identityNumber,
        address: address,
        notes: notes,
      );
      _showMessage('Cloud sync failed. Teacher saved locally.');
    }
  }

  Future<void> _openCreateClassDialog() async {
    await _openClassDialog();
  }

  Future<void> _openEditClassDialog(SchoolClass schoolClass) async {
    await _openClassDialog(existing: schoolClass);
  }

  Future<void> _openClassDialog({SchoolClass? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    String? selectedTeacherId = existing?.teacherId;
    final selectedStudentIds = <String>{...?(existing?.studentIds)};

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              actionsOverflowDirection: VerticalDirection.down,
              actionsOverflowButtonSpacing: 8,
              title: Text(existing == null ? 'Create Class' : 'Edit Class'),
              content: _responsiveDialogContent(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _dialogFieldSpacing([
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Class Name',
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: selectedTeacherId,
                      decoration: const InputDecoration(labelText: 'Teacher'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Not assigned'),
                        ),
                        ..._teachers.map(
                          (teacher) => DropdownMenuItem<String>(
                            value: teacher.id,
                            child: Text('${teacher.name} (${teacher.subject})'),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() => selectedTeacherId = value);
                      },
                    ),
                    Text(
                      'Assign Students',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    if (_students.isEmpty)
                      const Text('Add students first.')
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _students.map((student) {
                          final selected = selectedStudentIds.contains(
                            student.id,
                          );
                          return FilterChip(
                            label: Text(student.name),
                            selected: selected,
                            onSelected: (value) {
                              setDialogState(() {
                                if (value) {
                                  selectedStudentIds.add(student.id);
                                } else {
                                  selectedStudentIds.remove(student.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                  ]),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final className = nameController.text.trim();
                    if (className.isEmpty) {
                      _showError('Please enter class name.');
                      return;
                    }

                    Navigator.pop(dialogContext);
                    await _saveClass(
                      existing: existing,
                      name: className,
                      teacherId: selectedTeacherId,
                      studentIds: selectedStudentIds.toList(),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    _disposeControllersLater([nameController]);
  }

  Future<void> _saveClass({
    required SchoolClass? existing,
    required String name,
    required String? teacherId,
    required List<String> studentIds,
  }) async {
    if (_isLocalMode) {
      _saveClassLocal(
        existing: existing,
        name: name,
        teacherId: teacherId,
        studentIds: studentIds,
      );
      _showMessage('Class saved locally.');
      return;
    }

    final uid = _requireUid();
    if (uid == null) {
      return;
    }

    try {
      if (existing == null) {
        await _service.createClass(
          uid: uid,
          name: name,
          teacherId: teacherId,
          studentIds: studentIds,
        );
      } else {
        final keptAttendance = <String, bool>{};
        for (final studentId in studentIds) {
          keptAttendance[studentId] = existing.attendance[studentId] ?? false;
        }
        await _service.updateClass(
          uid: uid,
          id: existing.id,
          name: name,
          teacherId: teacherId,
          studentIds: studentIds,
          attendance: keptAttendance,
        );
      }
      _showMessage('Class saved.');
    } catch (error) {
      _activateLocalMode(error);
      _saveClassLocal(
        existing: existing,
        name: name,
        teacherId: teacherId,
        studentIds: studentIds,
      );
      _showMessage('Cloud sync failed. Class saved locally.');
    }
  }

  Future<void> _deleteStudent(SchoolStudent student) async {
    if (_isLocalMode) {
      _deleteStudentLocal(student);
      _showMessage('Student deleted locally.');
      return;
    }

    final uid = _requireUid();
    if (uid == null) {
      return;
    }

    try {
      await _service.deleteStudent(uid: uid, studentId: student.id);
      _showMessage('Student deleted.');
    } catch (error) {
      _activateLocalMode(error);
      _deleteStudentLocal(student);
      _showMessage('Cloud sync failed. Student deleted locally.');
    }
  }

  Future<void> _deleteTeacher(SchoolTeacher teacher) async {
    if (_isLocalMode) {
      _deleteTeacherLocal(teacher);
      _showMessage('Teacher deleted locally.');
      return;
    }

    final uid = _requireUid();
    if (uid == null) {
      return;
    }

    try {
      await _service.deleteTeacher(uid: uid, teacherId: teacher.id);
      _showMessage('Teacher deleted.');
    } catch (error) {
      _activateLocalMode(error);
      _deleteTeacherLocal(teacher);
      _showMessage('Cloud sync failed. Teacher deleted locally.');
    }
  }

  Future<void> _deleteClass(SchoolClass schoolClass) async {
    if (_isLocalMode) {
      _deleteClassLocal(schoolClass);
      _showMessage('Class deleted locally.');
      return;
    }

    final uid = _requireUid();
    if (uid == null) {
      return;
    }

    try {
      await _service.deleteClass(uid: uid, classId: schoolClass.id);
      _showMessage('Class deleted.');
    } catch (error) {
      _activateLocalMode(error);
      _deleteClassLocal(schoolClass);
      _showMessage('Cloud sync failed. Class deleted locally.');
    }
  }

  Future<void> _markAttendance({
    required SchoolClass schoolClass,
    required String studentId,
    required bool isPresent,
  }) async {
    if (_isLocalMode) {
      _markAttendanceLocal(
        schoolClass: schoolClass,
        studentId: studentId,
        isPresent: isPresent,
      );
      return;
    }

    final uid = _requireUid();
    if (uid == null) {
      return;
    }

    try {
      final updatedAttendance = Map<String, bool>.from(schoolClass.attendance);
      updatedAttendance[studentId] = isPresent;
      await _service.markAttendance(
        uid: uid,
        classId: schoolClass.id,
        attendance: updatedAttendance,
      );
    } catch (error) {
      _activateLocalMode(error);
      _markAttendanceLocal(
        schoolClass: schoolClass,
        studentId: studentId,
        isPresent: isPresent,
      );
      _showMessage('Cloud sync failed. Attendance updated locally.');
    }
  }

  String? _requireUid() {
    final uid = _activeUid ?? _auth.user?.uid;
    if (uid == null) {
      _showError('Please log in again.');
      return null;
    }
    return uid;
  }

  void _activateLocalMode(Object error) {
    final message = _toFriendlySyncError(error.toString());
    if (!mounted) {
      return;
    }
    _safeSetState(() {
      _isLocalMode = true;
      _syncError = message;
      _isSyncing = false;
    });
  }

  void _tryCloudSync() {
    final uid = _auth.user?.uid;
    if (uid == null) {
      _showError('Please log in again.');
      return;
    }
    setState(() {
      _activeUid = uid;
      _isLocalMode = false;
      _syncError = null;
    });
    _bindData(uid);
  }

  void _saveStudentLocal({
    required SchoolStudent? existing,
    required String name,
    required String rollNumber,
    required String grade,
    required String age,
    required String phoneNumber,
    required String parentName,
    required String parentIdentityNumber,
    required String studentIdentityNumber,
    required String photoUrl,
    required String notes,
  }) {
    final id = existing?.id ?? _nextLocalId();
    final updated = SchoolStudent(
      id: id,
      name: name,
      rollNumber: rollNumber,
      grade: grade,
      age: age,
      phoneNumber: phoneNumber,
      parentName: parentName,
      parentIdentityNumber: parentIdentityNumber,
      studentIdentityNumber: studentIdentityNumber,
      photoUrl: photoUrl,
      notes: notes,
    );
    _safeSetState(() {
      final index = _students.indexWhere((item) => item.id == id);
      if (index == -1) {
        _students = [..._students, updated];
      } else {
        final next = [..._students];
        next[index] = updated;
        _students = next;
      }
    });
  }

  void _saveTeacherLocal({
    required SchoolTeacher? existing,
    required String name,
    required String subject,
    required String email,
    required String age,
    required String qualifications,
    required String phoneNumber,
    required String identityNumber,
    required String address,
    required String notes,
  }) {
    final id = existing?.id ?? _nextLocalId();
    final updated = SchoolTeacher(
      id: id,
      name: name,
      subject: subject,
      email: email,
      age: age,
      qualifications: qualifications,
      phoneNumber: phoneNumber,
      identityNumber: identityNumber,
      address: address,
      notes: notes,
    );
    _safeSetState(() {
      final index = _teachers.indexWhere((item) => item.id == id);
      if (index == -1) {
        _teachers = [..._teachers, updated];
      } else {
        final next = [..._teachers];
        next[index] = updated;
        _teachers = next;
      }
    });
  }

  void _saveClassLocal({
    required SchoolClass? existing,
    required String name,
    required String? teacherId,
    required List<String> studentIds,
  }) {
    final id = existing?.id ?? _nextLocalId();
    final keptAttendance = <String, bool>{
      for (final studentId in studentIds) studentId: false,
    };
    if (existing != null) {
      for (final studentId in studentIds) {
        keptAttendance[studentId] = existing.attendance[studentId] ?? false;
      }
    }
    final updated = SchoolClass(
      id: id,
      name: name,
      teacherId: teacherId,
      studentIds: studentIds,
      attendance: keptAttendance,
    );
    _safeSetState(() {
      final index = _classes.indexWhere((item) => item.id == id);
      if (index == -1) {
        _classes = [..._classes, updated];
      } else {
        final next = [..._classes];
        next[index] = updated;
        _classes = next;
      }
    });
  }

  void _deleteStudentLocal(SchoolStudent student) {
    _safeSetState(() {
      _students = _students.where((item) => item.id != student.id).toList();
      _classes = _classes.map((schoolClass) {
        final updatedStudents = schoolClass.studentIds
            .where((id) => id != student.id)
            .toList();
        final updatedAttendance = Map<String, bool>.from(schoolClass.attendance)
          ..remove(student.id);
        return SchoolClass(
          id: schoolClass.id,
          name: schoolClass.name,
          teacherId: schoolClass.teacherId,
          studentIds: updatedStudents,
          attendance: updatedAttendance,
        );
      }).toList();
    });
  }

  void _deleteTeacherLocal(SchoolTeacher teacher) {
    _safeSetState(() {
      _teachers = _teachers.where((item) => item.id != teacher.id).toList();
      _classes = _classes.map((schoolClass) {
        return SchoolClass(
          id: schoolClass.id,
          name: schoolClass.name,
          teacherId: schoolClass.teacherId == teacher.id
              ? null
              : schoolClass.teacherId,
          studentIds: schoolClass.studentIds,
          attendance: schoolClass.attendance,
        );
      }).toList();
    });
  }

  void _deleteClassLocal(SchoolClass schoolClass) {
    _safeSetState(() {
      _classes = _classes.where((item) => item.id != schoolClass.id).toList();
    });
  }

  void _markAttendanceLocal({
    required SchoolClass schoolClass,
    required String studentId,
    required bool isPresent,
  }) {
    _safeSetState(() {
      final index = _classes.indexWhere((item) => item.id == schoolClass.id);
      if (index == -1) {
        return;
      }
      final attendance = Map<String, bool>.from(_classes[index].attendance);
      attendance[studentId] = isPresent;
      final updated = SchoolClass(
        id: _classes[index].id,
        name: _classes[index].name,
        teacherId: _classes[index].teacherId,
        studentIds: _classes[index].studentIds,
        attendance: attendance,
      );
      final next = [..._classes];
      next[index] = updated;
      _classes = next;
    });
  }

  String _nextLocalId() {
    _localCounter += 1;
    return 'local_${DateTime.now().microsecondsSinceEpoch}_$_localCounter';
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) {
      return;
    }
    final phase = SchedulerBinding.instance.schedulerPhase;
    final isFrameBusy =
        phase == SchedulerPhase.transientCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks ||
        phase == SchedulerPhase.persistentCallbacks;
    if (isFrameBusy) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(fn);
      });
      return;
    }
    setState(fn);
  }

  void _updateModules(VoidCallback mutate) {
    _safeSetState(mutate);
    unawaited(_persistModules());
  }

  void _disposeControllersLater(List<TextEditingController> controllers) {
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      for (final controller in controllers) {
        controller.dispose();
      }
    });
  }

  String _toFriendlySyncError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('cloud firestore api has not been used') ||
        lower.contains('firestore.googleapis.com/overview') ||
        (lower.contains('permission_denied') && lower.contains('firestore'))) {
      return 'Firestore API is not enabled for this project yet.';
    }
    if (lower.contains('network') ||
        lower.contains('unavailable') ||
        lower.contains('offline')) {
      return 'Unable to connect to Firestore right now.';
    }
    if (raw.length > 180) {
      return '${raw.substring(0, 180)}...';
    }
    return raw;
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(message)));
    });
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
      );
    });
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.footnote,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String footnote;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [scheme.surface, scheme.surfaceContainerHighest],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxHeight < 118 || constraints.maxWidth < 290;
            final titleStyle = compact
                ? Theme.of(context).textTheme.labelMedium
                : Theme.of(context).textTheme.labelLarge;
            final valueStyle = compact
                ? Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  )
                : Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  );
            final footnoteStyle = compact
                ? Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  )
                : Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  );

            if (compact) {
              return Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        ),
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: valueStyle,
                        ),
                        Text(
                          footnote,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: footnoteStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(title, style: titleStyle),
                const SizedBox(height: 2),
                Text(value, style: valueStyle),
                const SizedBox(height: 2),
                Text(
                  footnote,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: footnoteStyle,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardQuickActionChip extends StatelessWidget {
  const _DashboardQuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleActivityRow extends StatelessWidget {
  const _ModuleActivityRow({
    required this.label,
    required this.count,
    required this.value,
  });

  final String label;
  final int count;
  final double value;

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '$count • $percent%',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(minHeight: 7, value: value),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 540;
    if (compact) {
      return PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') {
            onEdit();
          } else {
            onDelete();
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      children: [
        IconButton(
          tooltip: 'Edit',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: 'Delete',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
    );
  }
}

class _SimpleModuleList extends StatelessWidget {
  const _SimpleModuleList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _EntityOption {
  const _EntityOption({
    required this.type,
    required this.id,
    required this.label,
  });

  final _TargetType type;
  final String id;
  final String label;
}

class _AiInsight {
  const _AiInsight({
    required this.headline,
    required this.points,
    required this.actions,
  });

  final String headline;
  final List<String> points;
  final List<_AiPromptAction> actions;
}

class _AiPromptAction {
  const _AiPromptAction({required this.label, required this.prompt});

  final String label;
  final String prompt;
}

class _ExamItem {
  const _ExamItem({
    required this.id,
    required this.title,
    required this.subject,
    required this.date,
    required this.targetType,
    required this.targetId,
  });

  final String id;
  final String title;
  final String subject;
  final String date;
  final _TargetType targetType;
  final String targetId;
}

class _FeeItem {
  const _FeeItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.targetType,
    required this.targetId,
    required this.paid,
  });

  final String id;
  final String title;
  final String amount;
  final String dueDate;
  final _TargetType targetType;
  final String targetId;
  final bool paid;

  _FeeItem copyWith({bool? paid}) {
    return _FeeItem(
      id: id,
      title: title,
      amount: amount,
      dueDate: dueDate,
      targetType: targetType,
      targetId: targetId,
      paid: paid ?? this.paid,
    );
  }
}

class _LibraryItem {
  const _LibraryItem({
    required this.id,
    required this.bookName,
    required this.dueDate,
    required this.targetType,
    required this.targetId,
    required this.returned,
  });

  final String id;
  final String bookName;
  final String dueDate;
  final _TargetType targetType;
  final String targetId;
  final bool returned;

  _LibraryItem copyWith({bool? returned}) {
    return _LibraryItem(
      id: id,
      bookName: bookName,
      dueDate: dueDate,
      targetType: targetType,
      targetId: targetId,
      returned: returned ?? this.returned,
    );
  }
}

class _TimetableItem {
  const _TimetableItem({
    required this.id,
    required this.day,
    required this.time,
    required this.subject,
    required this.teacherId,
    required this.classId,
  });

  final String id;
  final String day;
  final String time;
  final String subject;
  final String teacherId;
  final String classId;
}

class _TransportItem {
  const _TransportItem({
    required this.id,
    required this.routeName,
    required this.vehicleNo,
    required this.driver,
    required this.targetType,
    required this.targetId,
  });

  final String id;
  final String routeName;
  final String vehicleNo;
  final String driver;
  final _TargetType targetType;
  final String targetId;
}

class _NotificationItem {
  const _NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.targetType,
    required this.targetId,
  });

  final String id;
  final String title;
  final String message;
  final String date;
  final _TargetType targetType;
  final String targetId;
}
