import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../client_agent/presentation/pages/client_agent_chat_page.dart';
import '../../../login/data/auth_service.dart';
import '../../../login/presentation/pages/login_page.dart';
import '../../../tracking/presentation/pages/tracking_code_page.dart';
import '../../data/client_process_service.dart';
import '../../models/client_process_instance.dart';
import 'client_process_detail_page.dart';

class ClientProcessListPage extends StatefulWidget {
  const ClientProcessListPage({super.key});

  static const String routeName = '/client/processes';

  @override
  State<ClientProcessListPage> createState() => _ClientProcessListPageState();
}

class _ClientProcessListPageState extends State<ClientProcessListPage> {
  final _clientProcessService = ClientProcessService();
  final _authService = AuthService();

  bool _isLoading = true;
  String? _errorMessage;
  List<ClientProcessInstance> _processes = [];

  @override
  void initState() {
    super.initState();
    _loadProcesses();
  }

  Future<void> _loadProcesses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final processes = await _clientProcessService.getClientProcessInstances();
      processes.sort(_compareProcesses);

      if (!mounted) {
        return;
      }

      setState(() => _processes = processes);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int _compareProcesses(
    ClientProcessInstance first,
    ClientProcessInstance second,
  ) {
    final firstWeight = first.status == 'RUNNING' ? 0 : 1;
    final secondWeight = second.status == 'RUNNING' ? 0 : 1;

    if (firstWeight != secondWeight) {
      return firstWeight.compareTo(secondWeight);
    }

    final firstUpdated =
        first.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final secondUpdated =
        second.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

    return secondUpdated.compareTo(firstUpdated);
  }

  Future<void> _logout() async {
    await _authService.logout();

    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(LoginPage.routeName, (_) => false);
  }

  void _openDetail(ClientProcessInstance process) {
    Navigator.of(
      context,
    ).pushNamed(ClientProcessDetailPage.routeName, arguments: process.id);
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Sin fecha';
    }

    final local = date.toLocal();
    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  String _formatStatus(String status) {
    return switch (status) {
      'RUNNING' => 'En ejecución',
      'PENDING_ASSIGNMENT' => 'Pendiente de asignación',
      'COMPLETED' => 'Completado',
      'CANCELLED' => 'Cancelado',
      _ => status.isEmpty ? 'Sin estado' : status,
    };
  }

  Color _statusColor(String status) {
    return switch (status) {
      'COMPLETED' => AppColors.frSuccess,
      'CANCELLED' => AppColors.frDanger,
      'PENDING_ASSIGNMENT' => AppColors.frTaupe,
      _ => AppColors.frGold,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.frBlack,
      appBar: AppBar(
        title: const Text('Mis trámites'),
        backgroundColor: AppColors.frBlack,
        actions: [
          IconButton(
            tooltip: 'Agente inteligente',
            onPressed: () =>
                Navigator.of(context).pushNamed(ClientAgentChatPage.routeName),
            icon: const Icon(Icons.auto_awesome),
          ),
          IconButton(
            tooltip: 'Consultar por código',
            onPressed: () =>
                Navigator.of(context).pushNamed(TrackingCodePage.routeName),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.of(context).pushNamed(ClientAgentChatPage.routeName),
        backgroundColor: AppColors.frGold,
        foregroundColor: AppColors.frBlack,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Agente'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.frBrown, AppColors.frBlack],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadProcesses,
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingView(message: 'Cargando tus trámites...');
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(22),
        children: [
          _MessageCard(
            icon: Icons.error_outline,
            title: 'No se pudieron cargar tus trámites',
            message: _errorMessage!,
            actionText: 'Reintentar',
            onAction: _loadProcesses,
          ),
        ],
      );
    }

    if (_processes.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(22),
        children: [
          _MessageCard(
            icon: Icons.folder_open_outlined,
            title: 'Aún no tienes trámites registrados.',
            message: 'Cuando se cree un trámite a tu nombre, aparecerá aquí.',
            actionText: 'Consultar por código',
            onAction: () =>
                Navigator.of(context).pushNamed(TrackingCodePage.routeName),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(18),
      itemCount: _processes.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _HeaderCard(processCount: _processes.length);
        }

        final process = _processes[index - 1];
        final statusColor = _statusColor(process.status);

        return InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _openDetail(process),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.frCard.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.frGold.withValues(alpha: 0.20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            process.code,
                            style: const TextStyle(
                              color: AppColors.frGold,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            process.diagramName,
                            style: const TextStyle(
                              color: AppColors.frCream,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.frGold.withValues(alpha: 0.8),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _Badge(
                      text: _formatStatus(process.status),
                      color: statusColor,
                    ),
                    _Badge(
                      text: 'Actualizado ${_formatDate(process.updatedAt)}',
                      color: AppColors.frTaupe,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openDetail(process),
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('Ver detalle'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.frGold,
                      side: BorderSide(
                        color: AppColors.frGold.withValues(alpha: 0.55),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.processCount});

  final int processCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.frBlack.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.frGold.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FlowRoad',
            style: TextStyle(
              color: AppColors.frGold,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mis trámites',
            style: TextStyle(
              color: AppColors.frCream,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$processCount trámite${processCount == 1 ? '' : 's'} disponible${processCount == 1 ? '' : 's'}.',
            style: const TextStyle(color: AppColors.frMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.36)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionText,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionText;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.frBlack.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.frGold.withValues(alpha: 0.24)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.frGold, size: 42),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.frCream,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.frMuted, height: 1.4),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.frGold,
              foregroundColor: AppColors.frBlack,
            ),
            child: Text(actionText),
          ),
        ],
      ),
    );
  }
}
