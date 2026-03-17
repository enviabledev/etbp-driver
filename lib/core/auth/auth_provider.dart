import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:etbp_driver/core/api/api_client.dart';
import 'package:etbp_driver/core/api/endpoints.dart';
import 'package:etbp_driver/core/auth/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((_) => TokenStorage());
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(tokenStorage: ref.read(tokenStorageProvider)));

class AuthState {
  final bool isAuthenticated;
  final String? driverName;
  AuthState({this.isAuthenticated = false, this.driverName});
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier(ref.read(apiClientProvider), ref.read(tokenStorageProvider)));

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api;
  final TokenStorage _storage;
  AuthNotifier(this._api, this._storage) : super(AuthState());

  Future<bool> checkAuth() async {
    if (!await _storage.hasTokens()) return false;
    try {
      final res = await _api.get(Endpoints.driverProfile);
      state = AuthState(isAuthenticated: true, driverName: '${res.data['first_name']} ${res.data['last_name']}');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> login(String email, String password) async {
    final res = await _api.post(Endpoints.login, data: {'email': email, 'password': password});
    await _storage.saveTokens(res.data['access_token'], res.data['refresh_token']);
    final profile = await _api.get(Endpoints.driverProfile);
    state = AuthState(isAuthenticated: true, driverName: '${profile.data['first_name']} ${profile.data['last_name']}');
  }

  Future<void> logout() async {
    try {
      final rt = await _storage.getRefreshToken();
      if (rt != null) await _api.post(Endpoints.logout, data: {'refresh_token': rt});
    } catch (_) {}
    await _storage.clearTokens();
    state = AuthState();
  }
}
