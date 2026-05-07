import 'package:json_annotation/json_annotation.dart';

part 'current_user.g.dart';

enum UserRole {
  @JsonValue('CUSTOMER')
  customer,
  @JsonValue('COOK')
  cook,
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.phone,
    required this.name,
    required this.role,
  });

  final String id;
  final String phone;
  final String name;

  @JsonKey(fromJson: _roleFromJson, toJson: _roleToJson)
  final UserRole role;

  bool get isCustomer => role == UserRole.customer;
  bool get isCook => role == UserRole.cook;

  factory CurrentUser.fromJson(Map<String, dynamic> json) => _$CurrentUserFromJson(json);
  Map<String, dynamic> toJson() => _$CurrentUserToJson(this);
}

UserRole _roleFromJson(Object? raw) {
  final v = raw?.toString().trim();
  if (v == null || v.isEmpty) return UserRole.customer;
  switch (v.toUpperCase()) {
    case 'CUSTOMER':
      return UserRole.customer;
    case 'COOK':
      return UserRole.cook;
  }
  throw ArgumentError.value(raw, 'role', 'Unsupported role');
}

String _roleToJson(UserRole role) {
  switch (role) {
    case UserRole.customer:
      return 'CUSTOMER';
    case UserRole.cook:
      return 'COOK';
  }
}

