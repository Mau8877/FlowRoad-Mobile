import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/client_agent/presentation/pages/client_agent_chat_page.dart';
import 'features/client_processes/presentation/pages/client_process_detail_page.dart';
import 'features/client_processes/presentation/pages/client_process_list_page.dart';
import 'features/login/data/auth_service.dart';
import 'features/login/presentation/pages/login_page.dart';
import 'features/login/presentation/pages/register_page.dart';
import 'features/tracking/models/public_tracking.dart';
import 'features/tracking/presentation/pages/tracking_code_page.dart';
import 'features/tracking/presentation/pages/tracking_detail_page.dart';
import 'shared/widgets/loading_view.dart';

class FlowRoadMobileApp extends StatelessWidget {
  const FlowRoadMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlowRoad Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _StartupPage(),
      routes: {
        LoginPage.routeName: (_) => const LoginPage(),
        RegisterPage.routeName: (_) => const RegisterPage(),
        ClientAgentChatPage.routeName: (_) => const ClientAgentChatPage(),
        ClientProcessListPage.routeName: (_) => const ClientProcessListPage(),
        TrackingCodePage.routeName: (_) => const TrackingCodePage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == ClientProcessDetailPage.routeName) {
          final processInstanceId = settings.arguments;

          if (processInstanceId is String && processInstanceId.isNotEmpty) {
            return MaterialPageRoute(
              builder: (_) =>
                  ClientProcessDetailPage(processInstanceId: processInstanceId),
            );
          }

          return MaterialPageRoute(
            builder: (_) => const ClientProcessListPage(),
          );
        }

        if (settings.name == TrackingDetailPage.routeName) {
          final tracking = settings.arguments;

          if (tracking is PublicTracking) {
            return MaterialPageRoute(
              builder: (_) => TrackingDetailPage(tracking: tracking),
            );
          }

          return MaterialPageRoute(builder: (_) => const TrackingCodePage());
        }

        return null;
      },
    );
  }
}

class _StartupPage extends StatefulWidget {
  const _StartupPage();

  @override
  State<_StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<_StartupPage> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    final isAuthenticated = await _authService.isAuthenticated();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(
      isAuthenticated ? ClientProcessListPage.routeName : LoginPage.routeName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: LoadingView(message: 'Preparando FlowRoad Mobile...'),
    );
  }
}
