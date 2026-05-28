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

  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      if (!canCheck || !isDeviceSupported) return false;
      final biometrics = await _auth.getAvailableBiometrics();
      return biometrics.isNotEmpty;
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
        localizedReason: 'Usa tu huella dactilar para iniciar sesión',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (!ok) return null;
      final email = await _storage.read(key: _keyEmail);
      final password = await _storage.read(key: _keyPassword);
      if (email == null || password == null) return null;
      return (email: email, password: password);
    } on PlatformException {
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
