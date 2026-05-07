import 'package:json_annotation/json_annotation.dart';

part 'order_detail.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class OrderDetail {
  const OrderDetail({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.totalCop,
    required this.quantity,
    required this.fulfillmentType,
    required this.mealPublicationId,
    required this.timeline,
    this.notes,
    this.mealTitle,
    this.mealPhotoUrl,
    this.cookName,
    this.cookAvatarUrl,
    this.cookPhone,
    this.cookBio,
    this.publicationStatus,
    this.stockAvailable,
    this.customerName,
    this.customerPhone,
    this.customerAvatarUrl,
  });

  final String id;
  final String status;
  final DateTime createdAt;
  final int totalCop;
  final int quantity;
  final String fulfillmentType;
  final String? mealPublicationId;
  final String? notes;

  final List<OrderStatusEvent> timeline;

  // Enrichment (nullable depending on role and data availability)
  final String? mealTitle;
  final String? mealPhotoUrl;

  final String? cookName;
  final String? cookAvatarUrl;
  final String? cookPhone;
  final String? cookBio;

  final String? publicationStatus;
  final int? stockAvailable;

  final String? customerName;
  final String? customerPhone;
  final String? customerAvatarUrl;

  factory OrderDetail.fromJson(Map<String, dynamic> json) =>
      _$OrderDetailFromJson(json);

  Map<String, dynamic> toJson() => _$OrderDetailToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class OrderStatusEvent {
  const OrderStatusEvent({
    required this.fromStatus,
    required this.toStatus,
    required this.occurredAt,
    required this.actorUserId,
  });

  final String? fromStatus;
  final String toStatus;
  final DateTime occurredAt;
  final String actorUserId;

  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) =>
      _$OrderStatusEventFromJson(json);

  Map<String, dynamic> toJson() => _$OrderStatusEventToJson(this);
}

