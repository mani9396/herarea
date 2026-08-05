import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/models/user_model.dart';
import 'package:shared/services/api_client_interface.dart';
import 'package:shared/services/dio_api_client.dart';

/// Riverpod state controller for maintaining the active JWT Token and authenticated
/// [UserModel] across all HER AREA applications (app_user, app_vendor, app_admin).
class AuthSessionState {
  final String? accessToken;
  final String? refreshToken;
  final UserModel? currentUser;

  const AuthSessionState({this.accessToken, this.refreshToken, this.currentUser});

  bool get isAuthenticated => accessToken != null && accessToken!.isNotEmpty;
  bool get isApprovedVendor => currentUser != null && currentUser!.isApprovedVendor;

  AuthSessionState copyWith({String? accessToken, String? refreshToken, UserModel? currentUser}) {
    return AuthSessionState(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      currentUser: currentUser ?? this.currentUser,
    );
  }
}

class AuthSessionNotifier extends StateNotifier<AuthSessionState> {
  AuthSessionNotifier() : super(const AuthSessionState());

  void setTokens(String access, {String? refresh, UserModel? user}) {
    state = state.copyWith(accessToken: access, refreshToken: refresh, currentUser: user);
  }

  void setUser(UserModel user) {
    state = state.copyWith(currentUser: user);
  }

  void logout() {
    state = const AuthSessionState();
  }
}

/// Singleton authentication session state provider
final authSessionProvider = StateNotifierProvider<AuthSessionNotifier, AuthSessionState>((ref) {
  return AuthSessionNotifier();
});

/// Production network client provider automatically kept synchronous with JWT Token rotations
final apiClientProvider = Provider<IApiClient>((ref) {
  final client = DioApiClient();
  final authState = ref.watch(authSessionProvider);
  
  if (authState.accessToken != null && authState.accessToken!.isNotEmpty) {
    client.setAuthToken(authState.accessToken);
  } else {
    client.setAuthToken(null);
  }
  
  return client;
});
