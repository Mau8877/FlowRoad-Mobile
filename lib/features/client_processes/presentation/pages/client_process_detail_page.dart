import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../data/client_process_service.dart';
import '../../models/client_document_expedient.dart';
import '../../models/client_document_file.dart';
import '../../models/client_document_item.dart';
import '../../models/client_document_requirement.dart';
import '../../models/client_process_instance.dart';

class ClientProcessDetailPage extends StatefulWidget {
  const ClientProcessDetailPage({super.key, required this.processInstanceId});

  static const String routeName = '/client/processes/detail';

  final String processInstanceId;

  @override
  State<ClientProcessDetailPage> createState() =>
      _ClientProcessDetailPageState();
}

class _ClientProcessDetailPageState extends State<ClientProcessDetailPage> {
  final _clientProcessService = ClientProcessService();

  bool _isLoading = true;
  String? _errorMessage;
  ClientProcessInstance? _process;
  ClientDocumentExpedient? _documents;
  String? _busyRequirementId;
  String? _busyAction;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        _clientProcessService.getClientProcessInstanceDetail(
          widget.processInstanceId,
        ),
        _clientProcessService.getClientDocuments(widget.processInstanceId),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _process = results[0] as ClientProcessInstance;
        _documents = results[1] as ClientDocumentExpedient;
      });
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

  Future<void> _refreshDocuments() async {
    final documents = await _clientProcessService.getClientDocuments(
      widget.processInstanceId,
    );

    if (!mounted) {
      return;
    }

    setState(() => _documents = documents);
  }

  Future<void> _downloadDocument(ClientDocumentItem item) async {
    final currentFile = item.currentFile;

    if (!item.canRead || currentFile == null) {
      return;
    }

    _setBusy(item, 'download');

    try {
      final download = await _clientProcessService.getClientDocumentDownloadUrl(
        processInstanceId: widget.processInstanceId,
        documentFileId: currentFile.id,
      );

      final uri = Uri.tryParse(download.downloadUrl);

      if (uri == null ||
          !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _showSnackBar('No se pudo abrir el documento.');
      }
    } catch (error) {
      _showSnackBar(_errorText(error));
    } finally {
      _clearBusy();
    }
  }

  Future<void> _uploadDocument(ClientDocumentItem item) async {
    if (!item.canUpload || item.currentFile != null) {
      return;
    }

    final pickedFile = await _pickAndValidateFile(item.requirement);

    if (pickedFile == null) {
      return;
    }

    _setBusy(item, 'upload');

    try {
      await _clientProcessService.uploadClientDocument(
        processInstanceId: widget.processInstanceId,
        documentRequirementId: item.requirement.id,
        filePath: pickedFile.path,
        fileBytes: pickedFile.bytes,
        fileName: pickedFile.name,
      );
      await _refreshDocuments();
      _showSnackBar('Documento subido correctamente.');
    } catch (error) {
      _showSnackBar(_errorText(error));
    } finally {
      _clearBusy();
    }
  }

  Future<void> _replaceDocument(ClientDocumentItem item) async {
    final currentFile = item.currentFile;

    if (!item.canReplace || currentFile == null) {
      return;
    }

    final pickedFile = await _pickAndValidateFile(item.requirement);

    if (pickedFile == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('¿Reemplazar este documento?'),
          content: Text(
            'Se subirá "${pickedFile.name}" como nueva versión del documento.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reemplazar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    _setBusy(item, 'replace');

    try {
      await _clientProcessService.replaceClientDocument(
        processInstanceId: widget.processInstanceId,
        documentFileId: currentFile.id,
        filePath: pickedFile.path,
        fileBytes: pickedFile.bytes,
        fileName: pickedFile.name,
      );
      await _refreshDocuments();
      _showSnackBar('Documento reemplazado correctamente.');
    } catch (error) {
      _showSnackBar(_errorText(error));
    } finally {
      _clearBusy();
    }
  }

  Future<PlatformFile?> _pickAndValidateFile(
    ClientDocumentRequirement requirement,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
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

    final validationError = _validateFile(requirement, file);

    if (validationError != null) {
      _showSnackBar(validationError);
      return null;
    }

    return file;
  }

  String? _validateFile(
    ClientDocumentRequirement requirement,
    PlatformFile file,
  ) {
    final maxFileSizeMb = requirement.maxFileSizeMb;

    if (maxFileSizeMb > 0) {
      final maxBytes = maxFileSizeMb * 1024 * 1024;

      if (file.size > maxBytes) {
        return 'El archivo supera el tamaño máximo de $maxFileSizeMb MB.';
      }
    }

    final allowedTypes = requirement.allowedFileTypes;

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

  void _setBusy(ClientDocumentItem item, String action) {
    setState(() {
      _busyRequirementId = item.requirement.id;
      _busyAction = action;
    });
  }

  void _clearBusy() {
    if (!mounted) {
      return;
    }

    setState(() {
      _busyRequirementId = null;
      _busyAction = null;
    });
  }

  bool _isBusy(ClientDocumentItem item, [String? action]) {
    if (_busyRequirementId != item.requirement.id) {
      return false;
    }

    return action == null || _busyAction == action;
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.frBrown),
    );
  }

  String _errorText(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return error.toString();
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
      'UPLOADED' => 'Subido',
      'PENDING' => 'Pendiente',
      _ => status.isEmpty ? 'Sin estado' : status,
    };
  }

  Color _statusColor(String status) {
    return switch (status) {
      'COMPLETED' => AppColors.frSuccess,
      'CANCELLED' => AppColors.frDanger,
      'PENDING_ASSIGNMENT' => AppColors.frTaupe,
      'UPLOADED' => AppColors.frSuccess,
      'PENDING' => AppColors.frGold,
      _ => AppColors.frGold,
    };
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) {
      return '0 B';
    }

    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var index = 0;

    while (size >= 1024 && index < units.length - 1) {
      size = size / 1024;
      index++;
    }

    final decimals = index == 0 ? 0 : 1;
    return '${size.toStringAsFixed(decimals)} ${units[index]}';
  }

  String _formatAllowedTypes(List<String> allowedTypes) {
    return allowedTypes.isEmpty ? 'Sin restricción' : allowedTypes.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.frBlack,
      appBar: AppBar(
        title: const Text('Detalle del trámite'),
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
          child: RefreshIndicator(onRefresh: _loadDetail, child: _buildBody()),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingView(message: 'Cargando detalle del trámite...');
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(22),
        children: [
          _MessageCard(
            title: 'No se pudo cargar el trámite',
            message: _errorMessage!,
            onRetry: _loadDetail,
          ),
        ],
      );
    }

    final process = _process;
    final documents = _documents;

    if (process == null || documents == null) {
      return ListView(
        padding: const EdgeInsets.all(22),
        children: [
          _MessageCard(
            title: 'Sin información disponible',
            message: 'No se encontró el detalle del trámite.',
            onRetry: _loadDetail,
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _ProcessHeader(
          process: process,
          formatDate: _formatDate,
          formatStatus: _formatStatus,
          statusColor: _statusColor(process.status),
        ),
        const SizedBox(height: 18),
        const Text(
          'Documentos del trámite',
          style: TextStyle(
            color: AppColors.frGold,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        if (documents.items.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.frBlack.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.frGold.withValues(alpha: 0.22),
              ),
            ),
            child: const Text(
              'Este trámite no tiene documentos disponibles.',
              style: TextStyle(color: AppColors.frMuted),
            ),
          )
        else
          ...documents.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _DocumentCard(
                item: item,
                isBusy: _isBusy(item),
                isDownloading: _isBusy(item, 'download'),
                isUploading: _isBusy(item, 'upload'),
                isReplacing: _isBusy(item, 'replace'),
                formatDate: _formatDate,
                formatStatus: _formatStatus,
                statusColor: _statusColor(item.status),
                formatFileSize: _formatFileSize,
                formatAllowedTypes: _formatAllowedTypes,
                onDownload: () => _downloadDocument(item),
                onUpload: () => _uploadDocument(item),
                onReplace: () => _replaceDocument(item),
              ),
            );
          }),
      ],
    );
  }
}

class _ProcessHeader extends StatelessWidget {
  const _ProcessHeader({
    required this.process,
    required this.formatDate,
    required this.formatStatus,
    required this.statusColor,
  });

  final ClientProcessInstance process;
  final String Function(DateTime?) formatDate;
  final String Function(String) formatStatus;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.frBlack.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.frGold.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            process.code,
            style: const TextStyle(
              color: AppColors.frGold,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            process.diagramName,
            style: const TextStyle(
              color: AppColors.frCream,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _Pill(text: formatStatus(process.status), color: statusColor),
          const SizedBox(height: 18),
          _InfoRow(
            icon: Icons.person_outline,
            label: 'Cliente',
            value: process.clientName ?? 'Cliente no asociado',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.mail_outline,
            label: 'Email',
            value: process.clientEmail ?? 'Sin email',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Inicio',
            value: formatDate(process.startedAt),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.update,
            label: 'Actualización',
            value: formatDate(process.updatedAt),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.item,
    required this.isBusy,
    required this.isDownloading,
    required this.isUploading,
    required this.isReplacing,
    required this.formatDate,
    required this.formatStatus,
    required this.statusColor,
    required this.formatFileSize,
    required this.formatAllowedTypes,
    required this.onDownload,
    required this.onUpload,
    required this.onReplace,
  });

  final ClientDocumentItem item;
  final bool isBusy;
  final bool isDownloading;
  final bool isUploading;
  final bool isReplacing;
  final String Function(DateTime?) formatDate;
  final String Function(String) formatStatus;
  final Color statusColor;
  final String Function(int) formatFileSize;
  final String Function(List<String>) formatAllowedTypes;
  final VoidCallback onDownload;
  final VoidCallback onUpload;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context) {
    final requirement = item.requirement;
    final currentFile = item.currentFile;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.frCard.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.frGold.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Pill(
                text: requirement.required ? 'Obligatorio' : 'Opcional',
                color: requirement.required
                    ? AppColors.frDanger
                    : AppColors.frTaupe,
              ),
              _Pill(text: formatStatus(item.status), color: statusColor),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            requirement.name,
            style: const TextStyle(
              color: AppColors.frCream,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (requirement.description != null) ...[
            const SizedBox(height: 7),
            Text(
              requirement.description!,
              style: const TextStyle(color: AppColors.frMuted, height: 1.35),
            ),
          ],
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.attach_file,
            label: 'Tipos permitidos',
            value: formatAllowedTypes(requirement.allowedFileTypes),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.sd_storage_outlined,
            label: 'Tamaño máximo',
            value: '${requirement.maxFileSizeMb} MB',
          ),
          const SizedBox(height: 14),
          if (currentFile == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.frBlack.withValues(alpha: 0.46),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.frTaupe.withValues(alpha: 0.24),
                ),
              ),
              child: const Text(
                'Documento pendiente',
                style: TextStyle(
                  color: AppColors.frMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          else
            _CurrentFileCard(
              file: currentFile,
              formatDate: formatDate,
              formatFileSize: formatFileSize,
            ),
          const SizedBox(height: 14),
          _DocumentActions(
            item: item,
            isBusy: isBusy,
            isDownloading: isDownloading,
            isUploading: isUploading,
            isReplacing: isReplacing,
            onDownload: onDownload,
            onUpload: onUpload,
            onReplace: onReplace,
          ),
        ],
      ),
    );
  }
}

class _CurrentFileCard extends StatelessWidget {
  const _CurrentFileCard({
    required this.file,
    required this.formatDate,
    required this.formatFileSize,
  });

  final ClientDocumentFile file;
  final String Function(DateTime?) formatDate;
  final String Function(int) formatFileSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.frBlack.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.frGold.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.description_outlined, color: AppColors.frGold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  file.originalFileName,
                  style: const TextStyle(
                    color: AppColors.frCream,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _Pill(text: 'v${file.version}', color: AppColors.frGold),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.insert_drive_file_outlined,
            label: 'Extensión',
            value: file.fileExtension.isEmpty
                ? 'Sin extensión'
                : file.fileExtension,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.scale_outlined,
            label: 'Tamaño',
            value: formatFileSize(file.fileSizeBytes),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.person_outline,
            label: 'Subido por',
            value: file.uploadedByName,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Fecha',
            value: formatDate(file.createdAt),
          ),
        ],
      ),
    );
  }
}

class _DocumentActions extends StatelessWidget {
  const _DocumentActions({
    required this.item,
    required this.isBusy,
    required this.isDownloading,
    required this.isUploading,
    required this.isReplacing,
    required this.onDownload,
    required this.onUpload,
    required this.onReplace,
  });

  final ClientDocumentItem item;
  final bool isBusy;
  final bool isDownloading;
  final bool isUploading;
  final bool isReplacing;
  final VoidCallback onDownload;
  final VoidCallback onUpload;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context) {
    final currentFile = item.currentFile;
    final actions = <Widget>[];

    if (currentFile != null) {
      if (item.canRead) {
        actions.add(
          _ActionButton(
            label: isDownloading ? 'Preparando...' : 'Descargar',
            icon: Icons.download_outlined,
            onPressed: isBusy ? null : onDownload,
            outlined: true,
          ),
        );
      } else {
        actions.add(const _PermissionText('No disponible para descarga'));
      }

      if (item.canReplace) {
        actions.add(
          _ActionButton(
            label: isReplacing ? 'Reemplazando...' : 'Reemplazar',
            icon: Icons.upload_file_outlined,
            onPressed: isBusy ? null : onReplace,
          ),
        );
      } else {
        actions.add(const _PermissionText('Sin permiso para reemplazar'));
      }
    } else if (item.canUpload) {
      actions.add(
        _ActionButton(
          label: isUploading ? 'Subiendo...' : 'Subir',
          icon: Icons.upload_file_outlined,
          onPressed: isBusy ? null : onUpload,
        ),
      );
    } else {
      actions.add(const _PermissionText('Sin permiso para subir'));
    }

    return Wrap(spacing: 10, runSpacing: 10, children: actions);
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.frGold,
          side: BorderSide(color: AppColors.frGold.withValues(alpha: 0.55)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }

    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.frGold,
        foregroundColor: AppColors.frBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _PermissionText extends StatelessWidget {
  const _PermissionText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.frMuted,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.frGold, size: 19),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.frMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.frCream,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
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

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

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
          const Icon(Icons.error_outline, color: AppColors.frGold, size: 42),
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
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.frGold,
              foregroundColor: AppColors.frBlack,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
