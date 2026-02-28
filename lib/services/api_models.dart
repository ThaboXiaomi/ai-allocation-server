class ApiErrorEnvelope {
  final String code;
  final String message;
  final String? details;
  final String? requestId;

  ApiErrorEnvelope({
    required this.code,
    required this.message,
    this.details,
    this.requestId,
  });

  factory ApiErrorEnvelope.fromMap(Map<String, dynamic> map) {
    return ApiErrorEnvelope(
      code: (map['code'] ?? 'UNKNOWN').toString(),
      message: (map['message'] ?? 'Unknown error').toString(),
      details: map['details']?.toString(),
      requestId: map['requestId']?.toString(),
    );
  }
}

class AllocationsResponse {
  final List<dynamic> items;
  final int count;
  final int limit;
  final String? requestId;

  AllocationsResponse({
    required this.items,
    required this.count,
    required this.limit,
    this.requestId,
  });

  factory AllocationsResponse.fromMap(Map<String, dynamic> map) {
    final items = (map['items'] as List<dynamic>?) ?? const [];
    return AllocationsResponse(
      items: items,
      count: (map['count'] as num?)?.toInt() ?? items.length,
      limit: (map['limit'] as num?)?.toInt() ?? items.length,
      requestId: map['requestId']?.toString(),
    );
  }
}
