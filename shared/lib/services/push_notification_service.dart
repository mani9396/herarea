import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared/constants/api_endpoints.dart';
import 'package:shared/services/api_client_interface.dart';

/// Top-level background message handler required by Firebase Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handled automatically by native system or web service worker
  if (kDebugMode) {
    print('Handling background notification: ${message.messageId}');
  }
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  static const String webVapidKey =
      'BNfqMILd34ERN7oFwiPTr-_vGKHEPPwEtIFwCoajM7XO_dTxc1IJsxiLPqTUxInHjg8Ly0dQLO_EK2qLLFg26JQ';

  FirebaseMessaging? get _fcm {
    try {
      return FirebaseMessaging.instance;
    } catch (_) {
      return null;
    }
  }

  String? _lastToken;

  String? get currentToken => _lastToken;

  /// Request permissions and configure foreground/background listeners
  Future<void> initialize({
    String? vapidKey,
    void Function(String actionUrl)? onNotificationTap,
    void Function(RemoteMessage message)? onForegroundMessage,
  }) async {
    final fcm = _fcm;
    if (fcm == null) return;
    try {
      final effectiveVapidKey = vapidKey ?? (kIsWeb ? webVapidKey : null);

      // 1. Request user permission
      final settings = await fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        print('User notification permission status: ${settings.authorizationStatus}');
      }

      // 2. Fetch initial token if permitted
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        _lastToken = await fcm.getToken(vapidKey: effectiveVapidKey);
        if (kDebugMode) {
          print('FCM Registration Token: $_lastToken');
        }
      }

      // 3. Foreground message stream
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Foreground message received: ${message.notification?.title}');
        }
        onForegroundMessage?.call(message);
      });

      // 4. Background message click (app resumed from background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        final actionUrl = message.data['action_url']?.toString();
        if (actionUrl != null && actionUrl.isNotEmpty) {
          onNotificationTap?.call(actionUrl);
        }
      });

      // 5. Terminated app click (app launched from closed state)
      final initialMessage = await fcm.getInitialMessage();
      if (initialMessage != null) {
        final actionUrl = initialMessage.data['action_url']?.toString();
        if (actionUrl != null && actionUrl.isNotEmpty) {
          onNotificationTap?.call(actionUrl);
        }
      }

      // 6. Listen for token refresh events
      fcm.onTokenRefresh.listen((newToken) {
        _lastToken = newToken;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing push notification service: $e');
      }
    }
  }

  /// Register current device token with Django backend
  Future<bool> registerDeviceToken({
    required IApiClient apiClient,
    required String appType,
    String? vapidKey,
  }) async {
    try {
      final effectiveVapidKey = vapidKey ?? (kIsWeb ? webVapidKey : null);
      if (_lastToken == null || _lastToken!.isEmpty) {
        _lastToken = await _fcm?.getToken(vapidKey: effectiveVapidKey);
      }
      if (_lastToken == null || _lastToken!.isEmpty) {
        return false;
      }

      final platform = kIsWeb
          ? 'WEB'
          : (defaultTargetPlatform == TargetPlatform.iOS ? 'IOS' : 'ANDROID');

      await apiClient.post(
        ApiEndpoints.deviceTokenRegister,
        body: {
          'token': _lastToken,
          'platform': platform,
          'app_type': appType,
        },
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to register device token with backend: $e');
      }
      return false;
    }
  }

  /// Deactivate current device token with backend on logout
  Future<void> unregisterDeviceToken({required IApiClient apiClient}) async {
    try {
      if (_lastToken != null && _lastToken!.isNotEmpty) {
        await apiClient.post(
          ApiEndpoints.deviceTokenUnregister,
          body: {'token': _lastToken},
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to unregister device token on logout: $e');
      }
    }
  }
}
