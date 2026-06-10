import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  static final BiometricService instance = BiometricService._();
  BiometricService._();

  final _auth = LocalAuthentication();
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyEmail = 'bio_email';
  static const _keyPassword = 'bio_password';

  /// True if the device hardware supports biometrics (sensor exists).
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasSavedCredentials() async {
    try {
      final email = await _storage.read(key: _keyEmail);
      return email != null && email.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<({String email, String password})?> authenticate() async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Usa tu huella dactilar para iniciar sesión en Gestia',
        options: const AuthenticationOptions(
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      if (!ok) return null;
      final email = await _storage.read(key: _keyEmail);
      final password = await _storage.read(key: _keyPassword);
      if (email == null || password == null) return null;
      return (email: email, password: password);
    } on PlatformException catch (e) {
      // passBiometrics_ErrorLockout etc — let caller handle
      rethrow;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCredentials(String email, String password) async {
    try {
      await _storage.write(key: _keyEmail, value: email);
      await _storage.write(key: _keyPassword, value: password);
    } catch (_) {}
  }

  Future<void> clearCredentials() async {
    try {
      await _storage.delete(key: _keyEmail);
      await _storage.delete(key: _keyPassword);
    } catch (_) {}
  }

  Future<String?> getSavedEmail() async {
    try {
      return await _storage.read(key: _keyEmail);
    } catch (_) {
      return null;
    }
  }
}
