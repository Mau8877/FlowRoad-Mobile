class ClientAgentChatRequest {
  const ClientAgentChatRequest({this.chatId, required this.message});

  final String? chatId;
  final String message;

  Map<String, dynamic> toJson() {
    return {'chatId': chatId, 'message': message};
  }
}

class ClientAgentChatResponse {
  const ClientAgentChatResponse({
    required this.chatId,
    required this.reply,
    required this.conversationState,
    required this.availableOrganizations,
    required this.availableWorkflows,
    this.selectedOrganizationId,
    this.selectedWorkflowId,
    this.startRequirements,
    required this.readyToStart,
    this.processInstanceId,
    this.trackingCode,
    required this.needsHumanHelp,
  });

  final String? chatId;
  final String reply;
  final String conversationState;
  final List<ClientOrganization> availableOrganizations;
  final List<ClientWorkflow> availableWorkflows;
  final String? selectedOrganizationId;
  final String? selectedWorkflowId;
  final StartRequirements? startRequirements;
  final bool readyToStart;
  final String? processInstanceId;
  final String? trackingCode;
  final bool needsHumanHelp;

  factory ClientAgentChatResponse.fromJson(Map<String, dynamic> json) {
    return ClientAgentChatResponse(
      chatId: _readNullableString(json['chatId']),
      reply: json['reply']?.toString() ?? '',
      conversationState: json['conversationState']?.toString() ?? '',
      availableOrganizations: _readList(
        json['availableOrganizations'],
        ClientOrganization.fromJson,
      ),
      availableWorkflows: _readList(
        json['availableWorkflows'],
        ClientWorkflow.fromJson,
      ),
      selectedOrganizationId: _readNullableString(
        json['selectedOrganizationId'],
      ),
      selectedWorkflowId: _readNullableString(json['selectedWorkflowId']),
      startRequirements: _readStartRequirements(json['startRequirements']),
      readyToStart: _readBool(json['readyToStart']),
      processInstanceId: _readNullableString(json['processInstanceId']),
      trackingCode: _readNullableString(json['trackingCode']),
      needsHumanHelp: _readBool(json['needsHumanHelp']),
    );
  }
}

class ClientOrganization {
  const ClientOrganization({
    required this.id,
    required this.name,
    this.description,
  });

  final String id;
  final String name;
  final String? description;

  factory ClientOrganization.fromJson(Map<String, dynamic> json) {
    return ClientOrganization(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Empresa',
      description: _readNullableString(json['description']),
    );
  }
}

class ClientWorkflow {
  const ClientWorkflow({
    required this.id,
    required this.name,
    this.description,
  });

  final String id;
  final String name;
  final String? description;

  factory ClientWorkflow.fromJson(Map<String, dynamic> json) {
    return ClientWorkflow(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Tramite',
      description: _readNullableString(json['description']),
    );
  }
}

class StartRequirements {
  const StartRequirements({
    required this.workflowId,
    required this.workflowName,
    required this.initialNodeId,
    required this.requiredDocuments,
  });

  final String workflowId;
  final String workflowName;
  final String initialNodeId;
  final List<RequiredDocument> requiredDocuments;

  factory StartRequirements.fromJson(Map<String, dynamic> json) {
    return StartRequirements(
      workflowId: json['workflowId']?.toString() ?? '',
      workflowName: json['workflowName']?.toString() ?? '',
      initialNodeId: json['initialNodeId']?.toString() ?? '',
      requiredDocuments: _readList(
        json['requiredDocuments'],
        RequiredDocument.fromJson,
      ),
    );
  }
}

class RequiredDocument {
  const RequiredDocument({
    required this.id,
    required this.name,
    required this.required,
    required this.allowedTypes,
  });

  final String id;
  final String name;
  final bool required;
  final List<String> allowedTypes;

  factory RequiredDocument.fromJson(Map<String, dynamic> json) {
    return RequiredDocument(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Documento',
      required: _readBool(json['required']),
      allowedTypes: _readStringList(
        json['allowedTypes'] ?? json['allowedFileTypes'],
      ),
    );
  }
}

StartRequirements? _readStartRequirements(dynamic value) {
  if (value is! Map) {
    return null;
  }

  return StartRequirements.fromJson(
    value.map((key, value) => MapEntry(key.toString(), value)),
  );
}

List<T> _readList<T>(dynamic value, T Function(Map<String, dynamic>) fromJson) {
  if (value is! List) {
    return [];
  }

  return value.whereType<Map>().map((item) {
    return fromJson(item.map((key, value) => MapEntry(key.toString(), value)));
  }).toList();
}

List<String> _readStringList(dynamic value) {
  if (value is! List) {
    return [];
  }

  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList();
}

String? _readNullableString(dynamic value) {
  if (value == null) {
    return null;
  }

  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

bool _readBool(dynamic value) {
  if (value is bool) {
    return value;
  }

  return value?.toString().toLowerCase() == 'true';
}
