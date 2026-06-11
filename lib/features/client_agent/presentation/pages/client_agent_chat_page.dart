import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../client_processes/data/client_process_service.dart';
import '../../../client_processes/presentation/pages/client_process_detail_page.dart';
import '../../../client_processes/presentation/pages/client_process_list_page.dart';
import '../../../login/data/auth_service.dart';
import '../../../login/presentation/pages/login_page.dart';
import '../../../tracking/data/tracking_service.dart';
import '../../../tracking/presentation/pages/tracking_detail_page.dart';
import '../../data/client_agent_service.dart';
import '../../models/client_agent_chat.dart';

class ClientAgentChatPage extends StatefulWidget {
  const ClientAgentChatPage({super.key});

  static const String routeName = '/client/agent';

  @override
  State<ClientAgentChatPage> createState() => _ClientAgentChatPageState();
}

class _ClientAgentChatPageState extends State<ClientAgentChatPage> {
  final _agentService = ClientAgentService();
  final _processService = ClientProcessService();
  final _trackingService = TrackingService();
  final _authService = AuthService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  final List<_ChatEntry> _entries = [
    _ChatEntry.agent(
      'Hola, soy el agente de FlowRoad. Cuéntame qué tramite quieres iniciar.',
    ),
  ];
  final Map<String, _DocumentUploadState> _documentStates = {};

  String? _chatId;
  String? _processInstanceId;
  String? _trackingCode;
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendCurrentMessage() async {
    final message = _messageController.text.trim();

    if (message.isEmpty || _isSending) {
      return;
    }

    _messageController.clear();
    await _sendMessage(message);
  }

  Future<void> _sendMessage(String message) async {
    setState(() {
      _isSending = true;
      _entries.add(_ChatEntry.user(message));
    });
    _scrollToBottom();

    try {
      final response = await _agentService.sendMessage(
        chatId: _chatId,
        message: message,
      );

      if (!mounted) {
        return;
      }

      _applyAgentResponse(response);
    } catch (error) {
      await _handleError(error);
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  void _applyAgentResponse(ClientAgentChatResponse response) {
    setState(() {
      _chatId = response.chatId ?? _chatId;
      _processInstanceId = response.processInstanceId ?? _processInstanceId;
      _trackingCode = response.trackingCode ?? _trackingCode;

      if (response.reply.isNotEmpty) {
        _entries.add(_ChatEntry.agent(response.reply));
      }

      final shouldShowOrganizations =
          _isConversationState(response, 'SELECTING_ORGANIZATION') &&
          response.selectedOrganizationId == null;
      final shouldShowWorkflows =
          _isConversationState(response, 'SELECTING_WORKFLOW') &&
          response.selectedWorkflowId == null &&
          response.processInstanceId == null;

      if (shouldShowOrganizations && response.availableOrganizations.isNotEmpty) {
        _entries.add(
          _ChatEntry.options(
            title: 'Empresas disponibles',
            options: response.availableOrganizations
                .map((organization) => organization.name)
                .toList(),
          ),
        );
      }

      if (shouldShowWorkflows && response.availableWorkflows.isNotEmpty) {
        _entries.add(
          _ChatEntry.options(
            title: 'Tramites disponibles',
            options: response.availableWorkflows
                .map((workflow) => workflow.name)
                .toList(),
          ),
        );
      }

      final selectedWorkflowName = response.startRequirements?.workflowName;
      if (response.selectedWorkflowId != null &&
          response.processInstanceId == null &&
          selectedWorkflowName != null &&
          selectedWorkflowName.isNotEmpty) {
        _entries.add(_ChatEntry.selectedWorkflow(selectedWorkflowName));
      }

      final documents = response.startRequirements?.requiredDocuments ?? [];
      if (_processInstanceId != null && documents.isNotEmpty) {
        for (final document in documents) {
          _documentStates.putIfAbsent(document.id, () {
            return const _DocumentUploadState.pending();
          });
        }

        _entries.add(_ChatEntry.documents(documents));
      }

      if (_processInstanceId != null || _trackingCode != null) {
        _entries.add(_ChatEntry.actions());
      }
    });
    _scrollToBottom();
  }

  bool _isConversationState(
    ClientAgentChatResponse response,
    String expectedState,
  ) {
    return response.conversationState.toUpperCase() == expectedState;
  }

  Future<void> _uploadDocument(RequiredDocument document) async {
    final processInstanceId = _processInstanceId;

    if (processInstanceId == null || processInstanceId.isEmpty) {
      _showSnackBar('No se encontro el tramite para subir el documento.');
      return;
    }

    if (document.id.isEmpty) {
      _showSnackBar('No se encontro el requisito del documento.');
      return;
    }

    final pickedFile = await _pickAndValidateFile(document);

    if (pickedFile == null) {
      return;
    }

    setState(() {
      _documentStates[document.id] = const _DocumentUploadState.uploading();
    });

    try {
      await _processService.uploadClientDocument(
        processInstanceId: processInstanceId,
        documentRequirementId: document.id,
        filePath: pickedFile.path,
        fileBytes: pickedFile.bytes,
        fileName: pickedFile.name,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _documentStates[document.id] = const _DocumentUploadState.uploaded();
        _entries.add(_ChatEntry.agent('Documento subido correctamente.'));
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = _errorText(error);
      setState(() {
        _documentStates[document.id] = _DocumentUploadState.error(message);
      });
      await _handleError(error, fallbackMessage: message);
    }
  }

  Future<PlatformFile?> _pickAndValidateFile(RequiredDocument document) async {
    final allowedExtensions = _allowedPickerExtensions(document);
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: allowedExtensions.isEmpty ? FileType.any : FileType.custom,
      allowedExtensions: allowedExtensions.isEmpty ? null : allowedExtensions,
      withData: kIsWeb,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;

    if ((file.path == null || file.path!.isEmpty) && file.bytes == null) {
      _showSnackBar('No se pudo acceder al archivo seleccionado.');
      return null;
    }

    final validationError = _validateFile(document, file);
    if (validationError != null) {
      _showSnackBar(validationError);
      return null;
    }

    return file;
  }

  String? _validateFile(RequiredDocument document, PlatformFile file) {
    final allowedTypes = document.allowedTypes;

    if (allowedTypes.isEmpty) {
      return null;
    }

    final fileName = file.name.toLowerCase();
    final extension = (file.extension ?? '').toLowerCase();

    final isAllowed = allowedTypes.any((allowedType) {
      final normalized = allowedType.toLowerCase().trim();

      if (normalized.isEmpty) {
        return false;
      }

      if (normalized.contains('/')) {
        final mimeExtension = normalized.split('/').last;
        return extension == mimeExtension ||
            fileName.endsWith('.$mimeExtension');
      }

      final normalizedExtension = normalized.startsWith('.')
          ? normalized.substring(1)
          : normalized;
      return extension == normalizedExtension ||
          fileName.endsWith('.$normalizedExtension');
    });

    if (!isAllowed) {
      return 'Tipo no permitido. Usa: ${allowedTypes.join(', ')}.';
    }

    return null;
  }

  List<String> _allowedPickerExtensions(RequiredDocument document) {
    final extensions = <String>{};

    for (final allowedType in document.allowedTypes) {
      final normalized = allowedType.toLowerCase().trim();

      if (normalized.isEmpty) {
        continue;
      }

      if (normalized.contains('/')) {
        final mimeExtension = normalized.split('/').last;
        if (mimeExtension.isNotEmpty) {
          extensions.add(mimeExtension);
        }
        continue;
      }

      extensions.add(
        normalized.startsWith('.') ? normalized.substring(1) : normalized,
      );
    }

    return extensions.toList();
  }

  Future<void> _openTracking() async {
    final trackingCode = _trackingCode;

    if (trackingCode == null || trackingCode.isEmpty) {
      Navigator.of(context).pushNamed(ClientProcessDetailPage.routeName);
      return;
    }

    try {
      final tracking = await _trackingService.getTrackingByCode(trackingCode);

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pushNamed(TrackingDetailPage.routeName, arguments: tracking);
    } catch (error) {
      await _handleError(error);
    }
  }

  void _openProcessDetail() {
    final processInstanceId = _processInstanceId;

    if (processInstanceId == null || processInstanceId.isEmpty) {
      Navigator.of(context).pushNamed(ClientProcessListPage.routeName);
      return;
    }

    Navigator.of(
      context,
    ).pushNamed(ClientProcessDetailPage.routeName, arguments: processInstanceId);
  }

  void _startAnotherProcess() {
    setState(() {
      _chatId = null;
      _processInstanceId = null;
      _trackingCode = null;
      _documentStates.clear();
      _messageController.clear();
      _entries
        ..clear()
        ..add(
          _ChatEntry.agent(
            'Listo. Dime que tramite quieres iniciar ahora.',
          ),
        );
    });
    _scrollToBottom();
  }

  Future<void> _handleError(Object error, {String? fallbackMessage}) async {
    if (!mounted) {
      return;
    }

    if (error is ApiException) {
      if (error.statusCode == 401) {
        await _authService.logout();

        if (!mounted) {
          return;
        }

        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(LoginPage.routeName, (_) => false);
        return;
      }

      if (error.statusCode == 403) {
        _showSnackBar('Acceso denegado.');
        return;
      }
    }

    _showSnackBar(fallbackMessage ?? _errorText(error));
  }

  String _errorText(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return error.toString();
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.frBrown),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.frBlack,
      appBar: AppBar(
        title: const Text('Agente inteligente'),
        backgroundColor: AppColors.frBlack,
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
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                  itemCount: _entries.length + (_isSending ? 1 : 0),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (_isSending && index == _entries.length) {
                      return const _TypingBubble();
                    }

                    return _buildEntry(_entries[index]);
                  },
                ),
              ),
              _Composer(
                controller: _messageController,
                isSending: _isSending,
                onSubmitted: _sendCurrentMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntry(_ChatEntry entry) {
    return switch (entry.type) {
      _ChatEntryType.user => _MessageBubble(text: entry.text, isUser: true),
      _ChatEntryType.agent => _MessageBubble(text: entry.text, isUser: false),
      _ChatEntryType.options => _OptionCard(
        title: entry.title,
        options: entry.options,
        isSending: _isSending,
        onSelected: _sendMessage,
      ),
      _ChatEntryType.documents => _RequiredDocumentsCard(
        documents: entry.documents,
        states: _documentStates,
        onUpload: _uploadDocument,
      ),
      _ChatEntryType.selectedWorkflow => _SelectedWorkflowCard(
        workflowName: entry.text,
      ),
      _ChatEntryType.actions => _CompletionActions(
        hasProcess: _processInstanceId != null,
        hasTracking: _trackingCode != null,
        onOpenProcesses: () =>
            Navigator.of(context).pushNamed(ClientProcessListPage.routeName),
        onOpenDetail: _openProcessDetail,
        onOpenTracking: _openTracking,
        onStartAnother: _startAnotherProcess,
      ),
    };
  }
}

enum _ChatEntryType {
  user,
  agent,
  options,
  selectedWorkflow,
  documents,
  actions,
}

class _ChatEntry {
  const _ChatEntry._({
    required this.type,
    this.text = '',
    this.title = '',
    this.options = const [],
    this.documents = const [],
  });

  factory _ChatEntry.user(String text) {
    return _ChatEntry._(type: _ChatEntryType.user, text: text);
  }

  factory _ChatEntry.agent(String text) {
    return _ChatEntry._(type: _ChatEntryType.agent, text: text);
  }

  factory _ChatEntry.options({
    required String title,
    required List<String> options,
  }) {
    return _ChatEntry._(
      type: _ChatEntryType.options,
      title: title,
      options: options,
    );
  }

  factory _ChatEntry.documents(List<RequiredDocument> documents) {
    return _ChatEntry._(
      type: _ChatEntryType.documents,
      documents: documents,
    );
  }

  factory _ChatEntry.selectedWorkflow(String workflowName) {
    return _ChatEntry._(
      type: _ChatEntryType.selectedWorkflow,
      text: workflowName,
    );
  }

  factory _ChatEntry.actions() {
    return const _ChatEntry._(type: _ChatEntryType.actions);
  }

  final _ChatEntryType type;
  final String text;
  final String title;
  final List<String> options;
  final List<RequiredDocument> documents;
}

class _DocumentUploadState {
  const _DocumentUploadState._(this.status, [this.message]);

  const _DocumentUploadState.pending() : this._(_DocumentStatus.pending);

  const _DocumentUploadState.uploading() : this._(_DocumentStatus.uploading);

  const _DocumentUploadState.uploaded() : this._(_DocumentStatus.uploaded);

  const _DocumentUploadState.error(String message)
    : this._(_DocumentStatus.error, message);

  final _DocumentStatus status;
  final String? message;
}

enum _DocumentStatus { pending, uploading, uploaded, error }

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.text, required this.isUser});

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: isUser ? AppColors.frGold : AppColors.frCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isUser
                  ? AppColors.frGold
                  : AppColors.frGold.withValues(alpha: 0.20),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isUser ? AppColors.frBlack : AppColors.frCream,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: _SmallStatusCard(
        icon: Icons.auto_awesome,
        text: 'El agente esta respondiendo...',
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.title,
    required this.options,
    required this.isSending,
    required this.onSelected,
  });

  final String title;
  final List<String> options;
  final bool isSending;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.frGold,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options.map((option) {
              return OutlinedButton.icon(
                onPressed: isSending ? null : () => onSelected(option),
                icon: const Icon(Icons.touch_app_outlined, size: 18),
                label: Text(option),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.frGold,
                  side: BorderSide(
                    color: AppColors.frGold.withValues(alpha: 0.55),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RequiredDocumentsCard extends StatelessWidget {
  const _RequiredDocumentsCard({
    required this.documents,
    required this.states,
    required this.onUpload,
  });

  final List<RequiredDocument> documents;
  final Map<String, _DocumentUploadState> states;
  final ValueChanged<RequiredDocument> onUpload;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Documentos requeridos',
            style: TextStyle(
              color: AppColors.frGold,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...documents.map((document) {
            final state =
                states[document.id] ?? const _DocumentUploadState.pending();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RequiredDocumentTile(
                document: document,
                state: state,
                onUpload: () => onUpload(document),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SelectedWorkflowCard extends StatelessWidget {
  const _SelectedWorkflowCard({required this.workflowName});

  final String workflowName;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.frGold),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tramite seleccionado',
                  style: TextStyle(
                    color: AppColors.frMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  workflowName,
                  style: const TextStyle(
                    color: AppColors.frCream,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequiredDocumentTile extends StatelessWidget {
  const _RequiredDocumentTile({
    required this.document,
    required this.state,
    required this.onUpload,
  });

  final RequiredDocument document;
  final _DocumentUploadState state;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final isUploading = state.status == _DocumentStatus.uploading;
    final isUploaded = state.status == _DocumentStatus.uploaded;
    final statusColor = switch (state.status) {
      _DocumentStatus.uploaded => AppColors.frSuccess,
      _DocumentStatus.error => AppColors.frDanger,
      _DocumentStatus.uploading => AppColors.frGold,
      _DocumentStatus.pending => AppColors.frTaupe,
    };
    final statusText = switch (state.status) {
      _DocumentStatus.uploaded => 'Subido',
      _DocumentStatus.error => 'Error',
      _DocumentStatus.uploading => 'Subiendo',
      _DocumentStatus.pending => 'Pendiente',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.frBlack.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.frGold.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(
                text: document.required ? 'Obligatorio' : 'Opcional',
                color: document.required
                    ? AppColors.frDanger
                    : AppColors.frTaupe,
              ),
              _Pill(text: statusText, color: statusColor),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            document.name,
            style: const TextStyle(
              color: AppColors.frCream,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            document.allowedTypes.isEmpty
                ? 'Sin restriccion de formato'
                : document.allowedTypes.join(', ').toUpperCase(),
            style: const TextStyle(
              color: AppColors.frMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (state.message != null) ...[
            const SizedBox(height: 8),
            Text(
              state.message!,
              style: const TextStyle(
                color: AppColors.frDanger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: isUploading || isUploaded ? null : onUpload,
            icon: Icon(
              isUploaded ? Icons.check_circle_outline : Icons.upload_file,
            ),
            label: Text(
              isUploaded
                  ? 'Subido'
                  : isUploading
                  ? 'Subiendo...'
                  : 'Adjuntar documento',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.frGold,
              foregroundColor: AppColors.frBlack,
              disabledBackgroundColor: AppColors.frTaupe.withValues(
                alpha: 0.28,
              ),
              disabledForegroundColor: AppColors.frMuted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionActions extends StatelessWidget {
  const _CompletionActions({
    required this.hasProcess,
    required this.hasTracking,
    required this.onOpenProcesses,
    required this.onOpenDetail,
    required this.onOpenTracking,
    required this.onStartAnother,
  });

  final bool hasProcess;
  final bool hasTracking;
  final VoidCallback onOpenProcesses;
  final VoidCallback onOpenDetail;
  final VoidCallback onOpenTracking;
  final VoidCallback onStartAnother;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          FilledButton.icon(
            onPressed: onOpenProcesses,
            icon: const Icon(Icons.list_alt_outlined),
            label: const Text('Ver mis tramites'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.frGold,
              foregroundColor: AppColors.frBlack,
            ),
          ),
          if (hasProcess)
            OutlinedButton.icon(
              onPressed: onOpenDetail,
              icon: const Icon(Icons.description_outlined),
              label: const Text('Ver detalle'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.frGold,
                side: BorderSide(
                  color: AppColors.frGold.withValues(alpha: 0.55),
                ),
              ),
            ),
          if (hasTracking)
            OutlinedButton.icon(
              onPressed: onOpenTracking,
              icon: const Icon(Icons.route_outlined),
              label: const Text('Ver seguimiento'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.frGold,
                side: BorderSide(
                  color: AppColors.frGold.withValues(alpha: 0.55),
                ),
              ),
            ),
          TextButton.icon(
            onPressed: onStartAnother,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Iniciar otro tramite'),
            style: TextButton.styleFrom(foregroundColor: AppColors.frGold),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isSending,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      color: AppColors.frBlack.withValues(alpha: 0.88),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isSending,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSubmitted(),
              decoration: const InputDecoration(
                hintText: 'Escribe tu mensaje',
                prefixIcon: Icon(Icons.chat_bubble_outline),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            onPressed: isSending ? null : onSubmitted,
            icon: const Icon(Icons.send),
            tooltip: 'Enviar',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.frGold,
              foregroundColor: AppColors.frBlack,
              disabledBackgroundColor: AppColors.frTaupe.withValues(
                alpha: 0.28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.frCard.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.frGold.withValues(alpha: 0.20)),
      ),
      child: child,
    );
  }
}

class _SmallStatusCard extends StatelessWidget {
  const _SmallStatusCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.frCard.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.frGold.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.frGold, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.frMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
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
