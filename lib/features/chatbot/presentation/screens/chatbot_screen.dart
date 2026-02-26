import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../config/routes/route_constants.dart';
import '../../../../core/utils/role_permissions.dart';
import '../../../../core/widgets/session_menu_button.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/providers/auth_provider.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key, this.initialPrompt, this.moduleContext});

  final String? initialPrompt;
  final String? moduleContext;

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final AuthProvider _auth = Get.find<AuthProvider>();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = <_ChatMessage>[];
  final _SchoolChatbotService _chatbot = _SchoolChatbotService();

  bool _isResponding = false;
  List<String> _suggestions = const [];
  List<_ChatbotAction> _actions = const [];
  final List<String> _recentQueries = <String>[];

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onAuthChanged);
    final role = _auth.role;
    _messages.add(_ChatMessage.bot(_chatbot.welcomeMessage(role)));
    if ((widget.moduleContext ?? '').trim().isNotEmpty) {
      _messages.add(
        _ChatMessage.bot(
          'AI context: ${widget.moduleContext}. I will keep guidance focused on this module and your role.',
        ),
      );
    }
    _suggestions = _chatbot.starterPrompts(
      role,
      moduleContext: widget.moduleContext,
    );
    final initialPrompt = widget.initialPrompt?.trim();
    if (initialPrompt != null && initialPrompt.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _sendMessage(initialPrompt, role);
      });
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = _auth.role;

    return Scaffold(
      appBar: AppBar(
        title: const Text('School Assistant Chatbot'),
        actions: [
          IconButton(
            tooltip: 'Clear chat',
            onPressed: _clearChat,
            icon: const Icon(Icons.delete_sweep_rounded),
          ),
          const SessionMenuButton(showHome: true),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_isResponding ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isResponding && index == _messages.length) {
                  return const _TypingBubble();
                }
                final message = _messages[index];
                return _MessageBubble(message: message);
              },
            ),
          ),
          if (_suggestions.isNotEmpty)
            SizedBox(
              height: 52,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: _suggestions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final prompt = _suggestions[index];
                  return ActionChip(
                    label: Text(prompt),
                    onPressed: _isResponding
                        ? null
                        : () => _sendMessage(prompt, role),
                  );
                },
              ),
            ),
          if (_actions.isNotEmpty)
            SizedBox(
              height: 52,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: _actions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final action = _actions[index];
                  return ActionChip(
                    avatar: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: Text(action.label),
                    onPressed: () => Get.offNamed(action.route),
                  );
                },
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (value) => _sendMessage(value, role),
                      decoration: const InputDecoration(
                        hintText:
                            'Ask about timetable, fees, attendance, exams...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _isResponding
                        ? null
                        : () => _sendMessage(_controller.text, role),
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Send'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String raw, AppRole role) {
    final text = raw.trim();
    if (text.isEmpty) return;

    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage.user(text));
      _isResponding = true;
      _suggestions = const [];
      _actions = const [];
    });
    _recentQueries.add(text);
    if (_recentQueries.length > 6) {
      _recentQueries.removeAt(0);
    }
    _scrollToBottom();

    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final reply = _chatbot.reply(
        role: role,
        input: text,
        moduleContext: widget.moduleContext,
        history: _recentQueries,
      );
      setState(() {
        _messages.add(_ChatMessage.bot(reply.message));
        _suggestions = reply.suggestions;
        _actions = reply.actions;
        _isResponding = false;
      });
      _scrollToBottom();
    });
  }

  void _clearChat() {
    final role = _auth.role;
    setState(() {
      _messages
        ..clear()
        ..add(_ChatMessage.bot(_chatbot.welcomeMessage(role)))
        ..addAll(
          (widget.moduleContext ?? '').trim().isEmpty
              ? const []
              : [
                  _ChatMessage.bot(
                    'AI context: ${widget.moduleContext}. I will keep guidance focused on this module and your role.',
                  ),
                ],
        );
      _suggestions = _chatbot.starterPrompts(
        role,
        moduleContext: widget.moduleContext,
      );
      _actions = const [];
      _recentQueries.clear();
      _isResponding = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final scheme = Theme.of(context).colorScheme;
    final background = isUser ? scheme.primary : scheme.surfaceContainerHighest;
    final textColor = isUser ? scheme.onPrimary : scheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(message.text, style: TextStyle(color: textColor)),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text('Assistant is typing...'),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;

  factory _ChatMessage.user(String text) =>
      _ChatMessage(text: text, isUser: true);

  factory _ChatMessage.bot(String text) =>
      _ChatMessage(text: text, isUser: false);
}

class _ChatbotReply {
  const _ChatbotReply({
    required this.message,
    required this.suggestions,
    this.actions = const [],
  });

  final String message;
  final List<String> suggestions;
  final List<_ChatbotAction> actions;
}

class _ChatbotAction {
  const _ChatbotAction({required this.label, required this.route});

  final String label;
  final String route;
}

class _SchoolChatbotService {
  static const Map<String, String> _moduleLabels = {
    RouteConstants.attendance: 'Attendance',
    RouteConstants.exams: 'Exams',
    RouteConstants.results: 'Results',
    RouteConstants.fees: 'Fees',
    RouteConstants.timetable: 'Timetable',
    RouteConstants.library: 'Library',
    RouteConstants.notifications: 'Notifications',
    RouteConstants.transport: 'Transport',
  };

  static const Map<String, String> _normalizedModuleRoutes = {
    'attendance': RouteConstants.attendance,
    'exams': RouteConstants.exams,
    'results': RouteConstants.results,
    'fees': RouteConstants.fees,
    'timetable': RouteConstants.timetable,
    'library': RouteConstants.library,
    'notifications': RouteConstants.notifications,
    'transport': RouteConstants.transport,
    'subjects': RouteConstants.subjects,
    'dashboard': RouteConstants.home,
  };

  String welcomeMessage(AppRole role) {
    final modules = _allowedModuleNames(role);
    return 'Hi! I am your school assistant. I can help only with your role-allowed modules: ${modules.join(', ')}.';
  }

  List<String> starterPrompts(AppRole role, {String? moduleContext}) {
    final moduleRoute = _moduleRouteFromContext(moduleContext);
    if (moduleRoute != null &&
        canRoleAccessRoute(role: role, route: moduleRoute)) {
      final moduleLabel =
          _moduleLabels[moduleRoute] ?? moduleContext ?? 'module';
      return [
        'Give me AI insights for $moduleLabel.',
        'What risks should I avoid in $moduleLabel?',
        'Suggest next actions for $moduleLabel.',
      ];
    }

    switch (role) {
      case AppRole.admin:
        return const [
          'How can I manage roles?',
          'Show module setup tips',
          'How do I track attendance quickly?',
        ];
      case AppRole.teacher:
        return const [
          'How to mark attendance?',
          'How do I publish exam results?',
          'Show my teaching workflow',
        ];
      case AppRole.parent:
        return const [
          'How can I check my child results?',
          'Where can I see fee status?',
          'How to track timetable?',
        ];
      case AppRole.student:
        return const [
          'How do I check results?',
          'Where is my timetable?',
          'How can I access library resources?',
        ];
    }
  }

  _ChatbotReply reply({
    required AppRole role,
    required String input,
    String? moduleContext,
    List<String> history = const [],
  }) {
    final historyText = history.length <= 1
        ? ''
        : history.sublist(0, history.length - 1).join(' ').toLowerCase();
    final text = '$historyText ${input.toLowerCase()}';
    final contextualModuleRoute = _moduleRouteFromContext(moduleContext);

    if (_containsAny(text, const ['hello', 'hi', 'hey'])) {
      return _ChatbotReply(
        message:
            'Hello! I provide role-based help only. Ask about your allowed modules.',
        suggestions: starterPrompts(role, moduleContext: moduleContext),
        actions: _defaultActions(role, primaryRoute: contextualModuleRoute),
      );
    }

    if (_containsAny(text, const ['attendance', 'mark attendance'])) {
      return _moduleReply(
        role: role,
        route: RouteConstants.attendance,
        message: role == AppRole.teacher || role == AppRole.admin
            ? 'Open Attendance, select class + date, then mark Present/Absent and save.'
            : 'Open Attendance to view recent records for your linked profile and class.',
        suggestions: const [
          'Open Attendance module',
          'Attendance best practices',
        ],
        actions: _defaultActions(role, primaryRoute: RouteConstants.attendance),
      );
    }

    if (_containsAny(text, const ['result', 'grade', 'marks'])) {
      return _moduleReply(
        role: role,
        route: RouteConstants.results,
        message:
            'Use the Results module. Choose class/student filters to view or review performance trends.',
        suggestions: const ['Open Results', 'How to filter by class?'],
        actions: _defaultActions(role, primaryRoute: RouteConstants.results),
      );
    }

    if (_containsAny(text, const ['exam', 'test'])) {
      return _moduleReply(
        role: role,
        route: RouteConstants.exams,
        message:
            'Open Exams to schedule or edit tests, then sync linked Results entries.',
        suggestions: const ['Open Exams', 'Open Results'],
        actions: _defaultActions(role, primaryRoute: RouteConstants.exams),
      );
    }

    if (_containsAny(text, const ['fee', 'payment'])) {
      return _moduleReply(
        role: role,
        route: RouteConstants.fees,
        message:
            'Go to Fees to review pending/paid status and due timeline for each student.',
        suggestions: const ['Open Fees', 'How to read fee status?'],
        actions: _defaultActions(role, primaryRoute: RouteConstants.fees),
      );
    }

    if (_containsAny(text, const ['timetable', 'schedule'])) {
      return _moduleReply(
        role: role,
        route: RouteConstants.timetable,
        message:
            'Open Timetable to view period-wise schedules. Filter by class and day for faster lookup.',
        suggestions: const ['Open Timetable', 'How to filter by class?'],
        actions: _defaultActions(role, primaryRoute: RouteConstants.timetable),
      );
    }

    if (_containsAny(text, const ['library', 'book'])) {
      return _moduleReply(
        role: role,
        route: RouteConstants.library,
        message:
            'Use Library to review available books/resources and borrowing details.',
        suggestions: const ['Open Library', 'Show study support tips'],
        actions: _defaultActions(role, primaryRoute: RouteConstants.library),
      );
    }

    if (_containsAny(text, const ['transport', 'bus', 'route'])) {
      return _moduleReply(
        role: role,
        route: RouteConstants.transport,
        message:
            'Use Transport to check routes, vehicles, and schedule details.',
        suggestions: const ['Open Transport', 'How to search transport route?'],
        actions: _defaultActions(role, primaryRoute: RouteConstants.transport),
      );
    }

    if (_containsAny(text, const ['notification', 'notice', 'announcement'])) {
      return _moduleReply(
        role: role,
        route: RouteConstants.notifications,
        message:
            'Open Notifications to review latest school alerts and updates.',
        suggestions: const [
          'Open Notifications',
          'How to avoid missing notices?',
        ],
        actions: _defaultActions(
          role,
          primaryRoute: RouteConstants.notifications,
        ),
      );
    }

    if (_containsAny(text, const ['role', 'permission', 'access'])) {
      if (canRoleAccessRoute(
        role: role,
        route: RouteConstants.roleManagement,
      )) {
        return const _ChatbotReply(
          message:
              'Role changes are available in Role Management. Update role, teacher mapping, or student links there.',
          suggestions: ['Open Role Management', 'Open Profile'],
          actions: [
            _ChatbotAction(
              label: 'Open Role Management',
              route: RouteConstants.roleManagement,
            ),
            _ChatbotAction(
              label: 'Open Profile',
              route: RouteConstants.profile,
            ),
          ],
        );
      }
      return _accessDenied(role, 'Role Management');
    }

    if (contextualModuleRoute != null &&
        canRoleAccessRoute(role: role, route: contextualModuleRoute)) {
      final moduleLabel = _moduleLabels[contextualModuleRoute] ?? 'this module';
      return _ChatbotReply(
        message:
            'For $moduleLabel, start with current records, validate exceptions, then complete pending updates before closing today.',
        suggestions: starterPrompts(role, moduleContext: moduleContext),
        actions: _defaultActions(role, primaryRoute: contextualModuleRoute),
      );
    }

    return _ChatbotReply(
      message:
          'I can only help with modules available to your role: ${_allowedModuleNames(role).join(', ')}.',
      suggestions: starterPrompts(role, moduleContext: moduleContext),
      actions: _defaultActions(role),
    );
  }

  _ChatbotReply _moduleReply({
    required AppRole role,
    required String route,
    required String message,
    required List<String> suggestions,
    List<_ChatbotAction> actions = const [],
  }) {
    if (!canRoleAccessRoute(role: role, route: route)) {
      return _accessDenied(role, _moduleLabels[route] ?? 'This module');
    }
    return _ChatbotReply(
      message: message,
      suggestions: suggestions,
      actions: actions,
    );
  }

  _ChatbotReply _accessDenied(AppRole role, String moduleLabel) {
    return _ChatbotReply(
      message:
          '$moduleLabel is not available for your role. You can use: ${_allowedModuleNames(role).join(', ')}.',
      suggestions: starterPrompts(role),
      actions: _defaultActions(role),
    );
  }

  List<_ChatbotAction> _defaultActions(AppRole role, {String? primaryRoute}) {
    final actions = <_ChatbotAction>[];
    if (primaryRoute != null &&
        canRoleAccessRoute(role: role, route: primaryRoute)) {
      final label = _moduleLabels[primaryRoute] ?? 'Module';
      actions.add(_ChatbotAction(label: 'Open $label', route: primaryRoute));
    }
    actions.add(
      const _ChatbotAction(
        label: 'Open Profile',
        route: RouteConstants.profile,
      ),
    );
    return actions;
  }

  String? _moduleRouteFromContext(String? moduleContext) {
    final normalized = moduleContext?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    return _normalizedModuleRoutes[normalized];
  }

  List<String> _allowedModuleNames(AppRole role) {
    final modules = <String>[];
    for (final entry in _moduleLabels.entries) {
      if (canRoleAccessRoute(role: role, route: entry.key)) {
        modules.add(entry.value);
      }
    }
    return modules;
  }

  bool _containsAny(String source, List<String> needles) {
    for (final needle in needles) {
      if (source.contains(needle)) {
        return true;
      }
    }
    return false;
  }
}
