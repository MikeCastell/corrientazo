import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';

class CookProfileRepository {
  CookProfileRepository(this._ref);
  final Ref _ref;

  ApiClient get _api => _ref.read(apiClientProvider);

  Future<CookProfileDto> getMine() {
    return _api.getJson<CookProfileDto>(
      '/cook/profile',
      decode: (json) => CookProfileDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<CookProfileDto> update({
    String? businessName,
    String? avatarUrl,
    String? bio,
  }) {
    return _api.patchJson<CookProfileDto>(
      '/cook/profile',
      body: {'businessName': businessName, 'avatarUrl': avatarUrl, 'bio': bio},
      decode: (json) => CookProfileDto.fromJson(json as Map<String, dynamic>),
    );
  }
}

final cookProfileRepositoryProvider = Provider<CookProfileRepository>(
  (ref) => CookProfileRepository(ref),
);

class CookProfileDto {
  const CookProfileDto({
    required this.id,
    required this.bio,
    required this.userName,
    required this.userPhone,
    required this.userAvatarUrl,
  });

  final String id;
  final String? bio;
  final String? userName;
  final String? userPhone;
  final String? userAvatarUrl;

  factory CookProfileDto.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map?)?.cast<String, dynamic>();
    return CookProfileDto(
      id: json['id'] as String,
      bio: json['bio'] as String?,
      userName: user?['name'] as String?,
      userPhone: user?['phone'] as String?,
      userAvatarUrl: user?['avatar_url'] as String?,
    );
  }
}
