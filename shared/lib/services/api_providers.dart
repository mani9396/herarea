import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/constants/api_endpoints.dart';
import 'package:shared/models/user_model.dart';
import 'package:shared/services/api_client_interface.dart';
import 'package:shared/services/auth_token_storage.dart';
import 'package:shared/services/dio_api_client.dart';

/// Riverpod state controller for maintaining the active JWT Token and authenticated
/// [UserModel] across all HER AREA applications (app_user, app_vendor, app_admin).
class AuthSessionState {
  final String? accessToken;
  final String? refreshToken;
  final UserModel? currentUser;
  final bool isRestoring;

  const AuthSessionState({this.accessToken, this.refreshToken, this.currentUser, this.isRestoring = false});

  bool get isAuthenticated => accessToken != null && accessToken!.isNotEmpty;
  bool get isApprovedVendor => currentUser != null && currentUser!.isApprovedVendor;

  AuthSessionState copyWith({String? accessToken, String? refreshToken, UserModel? currentUser, bool? isRestoring}) {
    return AuthSessionState(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      currentUser: currentUser ?? this.currentUser,
      isRestoring: isRestoring ?? this.isRestoring,
    );
  }
}

class AuthSessionNotifier extends StateNotifier<AuthSessionState> {
  final AuthTokenStorage _storage;

  AuthSessionNotifier([AuthTokenStorage? storage])
      : _storage = storage ?? AuthTokenStorage(),
        super(const AuthSessionState()) {
    _initRestore();
  }

  Future<void> _initRestore() async {
    final access = await _storage.getAccessToken();
    final refresh = await _storage.getRefreshToken();
    final role = await _storage.getUserRole();
    if (access != null && access.isNotEmpty) {
      UserModel? user;
      if (role != null) {
        user = UserModel(
          id: '',
          phoneNumber: '',
          fullName: 'HER AREA User',
          role: UserRole.fromCode(role),
          studioStatus: role.toUpperCase() == 'VENDOR' ? 'APPROVED' : null,
        );
      }
      state = state.copyWith(accessToken: access, refreshToken: refresh, currentUser: user);
    }
  }

  Future<void> restoreSession(IApiClient apiClient) async {
    state = state.copyWith(isRestoring: true);
    final access = await _storage.getAccessToken();
    final refresh = await _storage.getRefreshToken();
    final role = await _storage.getUserRole();
    if (access != null && access.isNotEmpty) {
      state = state.copyWith(accessToken: access, refreshToken: refresh);
      apiClient.setAuthToken(access, refreshToken: refresh);
      try {
        final res = await apiClient.get(ApiEndpoints.userProfile);
        final user = UserModel.fromJson(res);
        state = state.copyWith(currentUser: user, isRestoring: false);
      } catch (_) {
        if (role != null) {
          final backupUser = UserModel(
            id: '',
            phoneNumber: '',
            fullName: 'HER AREA User',
            role: UserRole.fromCode(role),
            studioStatus: role.toUpperCase() == 'VENDOR' ? 'APPROVED' : null,
          );
          state = state.copyWith(currentUser: backupUser, isRestoring: false);
        } else {
          state = state.copyWith(isRestoring: false);
        }
      }
    } else {
      state = state.copyWith(isRestoring: false);
    }
  }

  Future<void> setTokens(String access, {String? refresh, UserModel? user, String? role}) async {
    await _storage.saveTokens(accessToken: access, refreshToken: refresh, role: role ?? user?.role.code);
    state = state.copyWith(accessToken: access, refreshToken: refresh, currentUser: user);
  }

  void setUser(UserModel user) {
    state = state.copyWith(currentUser: user);
  }

  Future<void> logout([IApiClient? apiClient]) async {
    if (apiClient != null && state.accessToken != null) {
      try {
        await apiClient.post(ApiEndpoints.logout, body: {'refresh': state.refreshToken});
      } catch (_) {
        // Ignore network failure on server logout during session termination
      }
    }
    await _storage.clearTokens();
    state = const AuthSessionState();
    apiClient?.setAuthToken(null, refreshToken: null);
  }
}

/// Singleton storage provider
final authTokenStorageProvider = Provider<AuthTokenStorage>((ref) {
  return AuthTokenStorage();
});

/// Singleton authentication session state provider
final authSessionProvider = StateNotifierProvider<AuthSessionNotifier, AuthSessionState>((ref) {
  final storage = ref.watch(authTokenStorageProvider);
  return AuthSessionNotifier(storage);
});

/// Production network client provider automatically kept synchronous with JWT Token rotations
final apiClientProvider = Provider<IApiClient>((ref) {
  final client = DioApiClient(
    onTokenRefreshed: (access, refresh) {
      ref.read(authSessionProvider.notifier).setTokens(access, refresh: refresh);
    },
    onRefreshFailed: () {
      ref.read(authSessionProvider.notifier).logout();
    },
  );
  final authState = ref.watch(authSessionProvider);
  
  if (authState.accessToken != null && authState.accessToken!.isNotEmpty) {
    client.setAuthToken(authState.accessToken, refreshToken: authState.refreshToken);
  } else {
    client.setAuthToken(null, refreshToken: null);
  }
  
  return client;
});
