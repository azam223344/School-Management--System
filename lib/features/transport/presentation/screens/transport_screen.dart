import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/module_ai_action_button.dart';
import '../../../../core/widgets/session_menu_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/transport_item.dart';
import '../controllers/transport_controller.dart';

class TransportScreen extends StatefulWidget {
  const TransportScreen({super.key});

  @override
  State<TransportScreen> createState() => _TransportScreenState();
}

class _TransportScreenState extends State<TransportScreen> {
  final TransportController _controller = Get.find<TransportController>();
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
    if (Get.isRegistered<TransportController>()) {
      Get.delete<TransportController>();
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
        title: const Text('Transport'),
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
          const ModuleAiActionButton(moduleName: 'Transport'),
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
              _buildLocalBanner('Local mode: transport not synced to cloud.'),
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
                  labelText: 'Search Routes',
                  hintText: 'Route, driver or vehicle',
                ),
                onChanged: (value) => setState(() => _search = value),
              ),
            ),
            FilledButton.icon(
              onPressed: _openAddDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Route'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final filtered = _filtered;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transport Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (filtered.isEmpty)
              const Text('No transport routes found.')
            else
              ...filtered.map(
                (item) => ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.directions_bus),
                  ),
                  title: Text('${item.routeName} (${item.vehicleNo})'),
                  subtitle: Text(
                    '${item.driver} | ${_targetTitle(item.targetType, item.targetId)}',
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

  List<TransportItem> get _filtered {
    final q = _search.trim().toLowerCase();
    return _controller.items.where((item) {
      if (q.isEmpty) return true;
      return item.routeName.toLowerCase().contains(q) ||
          item.vehicleNo.toLowerCase().contains(q) ||
          item.driver.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _openAddDialog() async {
    final routeController = TextEditingController();
    final vehicleController = TextEditingController();
    final driverController = TextEditingController();
    TransportTargetType targetType = TransportTargetType.student;
    String? targetId;

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
              children: [
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
                const SizedBox(height: 8),
                DropdownButtonFormField<TransportTargetType>(
                  initialValue: targetType,
                  decoration: const InputDecoration(labelText: 'Target Type'),
                  items: const [
                    DropdownMenuItem(
                      value: TransportTargetType.student,
                      child: Text('Student'),
                    ),
                    DropdownMenuItem(
                      value: TransportTargetType.teacher,
                      child: Text('Teacher'),
                    ),
                    DropdownMenuItem(
                      value: TransportTargetType.schoolClass,
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
                if (routeController.text.trim().isEmpty ||
                    vehicleController.text.trim().isEmpty ||
                    driverController.text.trim().isEmpty ||
                    targetId == null) {
                  _showError('Fill all transport fields.');
                  return;
                }
                _controller.addItem(
                  routeName: routeController.text.trim(),
                  vehicleNo: vehicleController.text.trim(),
                  driver: driverController.text.trim(),
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

  Future<void> _openEditDialog(TransportItem existing) async {
    final routeController = TextEditingController(text: existing.routeName);
    final vehicleController = TextEditingController(text: existing.vehicleNo);
    final driverController = TextEditingController(text: existing.driver);
    TransportTargetType targetType = existing.targetType;
    String? targetId = existing.targetId;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          actionsOverflowDirection: VerticalDirection.down,
          actionsOverflowButtonSpacing: 8,
          title: const Text('Edit Transport Route'),
          content: _responsiveDialogContent(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                const SizedBox(height: 8),
                DropdownButtonFormField<TransportTargetType>(
                  initialValue: targetType,
                  decoration: const InputDecoration(labelText: 'Target Type'),
                  items: const [
                    DropdownMenuItem(
                      value: TransportTargetType.student,
                      child: Text('Student'),
                    ),
                    DropdownMenuItem(
                      value: TransportTargetType.teacher,
                      child: Text('Teacher'),
                    ),
                    DropdownMenuItem(
                      value: TransportTargetType.schoolClass,
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
                if (routeController.text.trim().isEmpty ||
                    vehicleController.text.trim().isEmpty ||
                    driverController.text.trim().isEmpty ||
                    targetId == null) {
                  _showError('Fill all transport fields.');
                  return;
                }
                _controller.updateItem(
                  id: existing.id,
                  routeName: routeController.text.trim(),
                  vehicleNo: vehicleController.text.trim(),
                  driver: driverController.text.trim(),
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

  List<_EntityOption> _targetOptions(TransportTargetType type) {
    switch (type) {
      case TransportTargetType.student:
        return _controller.students
            .map((e) => _EntityOption(id: e.id, label: 'Student: ${e.name}'))
            .toList();
      case TransportTargetType.teacher:
        return _controller.teachers
            .map((e) => _EntityOption(id: e.id, label: 'Teacher: ${e.name}'))
            .toList();
      case TransportTargetType.schoolClass:
        return _controller.classes
            .map((e) => _EntityOption(id: e.id, label: 'Class: ${e.name}'))
            .toList();
    }
  }

  String _targetTitle(TransportTargetType type, String id) {
    switch (type) {
      case TransportTargetType.student:
        final item = _controller.students.where((e) => e.id == id).firstOrNull;
        return item == null ? 'Student' : 'Student: ${item.name}';
      case TransportTargetType.teacher:
        final item = _controller.teachers.where((e) => e.id == id).firstOrNull;
        return item == null ? 'Teacher' : 'Teacher: ${item.name}';
      case TransportTargetType.schoolClass:
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
