import 'package:json_annotation/json_annotation.dart';

part 'order_create_response.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class OrderCreateResponse {
  const OrderCreateResponse({
    required this.id,
    required this.status,
    required this.totalCop,
    required this.createdAt,
  });

  final String id;
  final String status;
  final int totalCop;
  final DateTime createdAt;

  factory OrderCreateResponse.fromJson(Map<String, dynamic> json) =>
      _$OrderCreateResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OrderCreateResponseToJson(this);
}

