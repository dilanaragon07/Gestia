import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageRepository {
  final _client = Supabase.instance.client;
  static const _bucket = 'payment-evidence';

  /// Uploads [file] and returns a signed URL valid for 10 years.
  /// Throws on failure.
  Future<String> uploadPaymentEvidence(File file, String paymentId) async {
    final ext = file.path.split('.').last.toLowerCase();
    final path = 'payments/$paymentId.$ext';

    await _client.storage.from(_bucket).upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );

    final signedUrl = await _client.storage
        .from(_bucket)
        .createSignedUrl(path, 60 * 60 * 24 * 365 * 10); // 10 years

    return signedUrl;
  }

  Future<void> deletePaymentEvidence(String paymentId, String ext) async {
    await _client.storage.from(_bucket).remove(['payments/$paymentId.$ext']);
  }
}
