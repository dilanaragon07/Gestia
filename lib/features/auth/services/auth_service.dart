import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/profile_repository.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  final _client = Supabase.instance.client;
  final _profileRepo = ProfileRepository();

  ProfileModel? _profile;

  User? get currentUser => _client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  ProfileModel? get profile => _profile;
  bool get isSuperadmin => _profile?.isSuperadmin ?? false;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> loadProfile() async {
    _profile = await _profileRepo.fetchMyProfile();
  }

  Future<void> signOut() async {
    _profile = null;
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}
