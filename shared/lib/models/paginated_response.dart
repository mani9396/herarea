/// Generic pagination wrapper designed to unwrap Django REST Framework's
/// [StandardResultsSetPagination] and [FlexibleLimitOffsetPagination] JSON metadata.
///
/// Schema:
/// {
///   "count": 125,
///   "next": "http://127.0.0.1:8000/api/v1/stores/?page=2",
///   "previous": null,
///   "results": [ ... ]
/// }
class PaginatedResponse<T> {
  final int count;
  final String? nextUrl;
  final String? previousUrl;
  final List<T> results;

  const PaginatedResponse({
    required this.count,
    this.nextUrl,
    this.previousUrl,
    required this.results,
  });

  bool get hasNext => nextUrl != null && nextUrl!.isNotEmpty;
  bool get hasPrevious => previousUrl != null && previousUrl!.isNotEmpty;

  factory PaginatedResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic> json) itemConverter) {
    final rawResults = json['results'];
    final List<T> items;
    if (rawResults is List) {
      items = rawResults.map((e) => itemConverter(e as Map<String, dynamic>)).toList();
    } else if (json['data'] is List) {
      items = (json['data'] as List).map((e) => itemConverter(e as Map<String, dynamic>)).toList();
    } else {
      items = [];
    }

    return PaginatedResponse<T>(
      count: (json['count'] as num?)?.toInt() ?? items.length,
      nextUrl: json['next']?.toString(),
      previousUrl: json['previous']?.toString(),
      results: items,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T item) itemSerializer) {
    return {
      'count': count,
      'next': nextUrl,
      'previous': previousUrl,
      'results': results.map(itemSerializer).toList(),
    };
  }
}
