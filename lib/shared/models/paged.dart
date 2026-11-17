import 'json_utils.dart';

class Paged<T> {
  final List<T> items;
  final int total;
  final int page;
  final int pages;

  const Paged(this.items, this.total, this.page, this.pages);

  bool get hasMore => page < pages;

  factory Paged.fromResponse(
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) parse,
  ) {
    final meta = asMap(body['meta']);
    final items = asMapList(body['data']).map(parse).toList();
    return Paged(
      items,
      asInt(meta['total'], items.length),
      asInt(meta['page'], 1),
      asInt(meta['pages'], 1),
    );
  }
}
