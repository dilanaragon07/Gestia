import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class ProfileRepository {
  final _client = Supabase.instance.client;

  Future<ProfileModel?> fetchMyProfile() async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', _client.auth.currentUser!.id)
        .maybeSingle();
    if (data == null) return null;
    return ProfileModel.fromJson(data);
  }

  Future<List<ProfileModel>> fetchAll() async {
    final response = await _client
        .from('profiles')
        .select()
        .order('created_at', ascending: true);
    return (response as List)
        .map((j) => ProfileModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> update(ProfileModel profile) async {
    await _client
        .from('profiles')
        .update(profile.toUpdateJson())
        .eq('id', profile.id);
  }

  Future<String?> createUser({
    required String email,
    required String password,
    required String fullName,
    String role = 'user',
  }) async {
    try {
      final response = await _client.functions.invoke(
        'create-user',
        body: {'email': email, 'password': password, 'full_name': fullName, 'role': role},
      );
      final data = response.data as Map<String, dynamic>?;
      if (data?['error'] != null) return data!['error'] as String;
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
