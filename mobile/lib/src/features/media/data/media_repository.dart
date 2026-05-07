import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';

class MediaRepository {
  MediaRepository(this._ref);
  final Ref _ref;

  ApiClient get _api => _ref.read(apiClientProvider);

  Future<String> uploadImage(File file) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });

    final resp = await _api.dio.post<Map<String, dynamic>>(
      '/media/upload',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );

    final url = resp.data?['url']?.toString();
    if (url == null || url.isEmpty) {
      throw const FormatException('Upload response missing url');
    }
    return url;
  }
}

final mediaRepositoryProvider = Provider<MediaRepository>(
  (ref) => MediaRepository(ref),
);
