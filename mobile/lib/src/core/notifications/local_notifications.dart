import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef OrderNotificationTapCallback = void Function(String orderId);

OrderNotificationTapCallback? _orderTapCallback;

class LocalNotifications {
  LocalNotifications();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Uint8List? _logoBytes;

  void setOrderTapHandler(OrderNotificationTapCallback? handler) {
    _orderTapCallback = handler;
  }

  Future<Uint8List> _logoBytesCached() async {
    if (_logoBytes != null) return _logoBytes!;
    final data = await rootBundle.load('assets/branding/logo_marca.png');
    _logoBytes = data.buffer.asUint8List();
    return _logoBytes!;
  }

  Future<void> initIfNeeded() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: android,
      iOS: ios,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.requestNotificationsPermission();
    }

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      final payload = launch!.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        _orderTapCallback?.call(payload);
      }
    }

    _initialized = true;
    if (kDebugMode) debugPrint('[notifications] initialized');
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    _orderTapCallback?.call(payload);
  }

  Future<void> showOrder({
    required String orderId,
    required String title,
    required String body,
    int? notificationId,
    String channelId = 'orders_status',
    String channelName = 'Estado del pedido',
    String? channelDescription =
        'Avisos cuando el cocinero actualiza tu pedido',
  }) async {
    await initIfNeeded();

    final id = notificationId ??
        orderId.hashCode.remainder(1 << 30).abs();
    final logo = await _logoBytesCached();
    final largeIcon = ByteArrayAndroidBitmap(logo);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        largeIcon: largeIcon,
        styleInformation: BigTextStyleInformation(body),
        playSound: true,
        enableVibration: true,
        ticker: title,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );

    await _plugin.show(
      id,
      title,
      body,
      details,
      payload: orderId,
    );
  }

  /// Compatibilidad con llamadas genéricas sin pedido asociado.
  Future<void> show({
    required String title,
    required String body,
    String? orderId,
    String channelId = 'orders',
    String channelName = 'Pedidos',
    String? channelDescription,
    int? id,
  }) async {
    if (orderId != null && orderId.isNotEmpty) {
      await showOrder(
        orderId: orderId,
        title: title,
        body: body,
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDescription,
      );
      return;
    }

    await initIfNeeded();
    final logo = await _logoBytesCached();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        largeIcon: ByteArrayAndroidBitmap(logo),
        styleInformation: BigTextStyleInformation(body),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    await _plugin.show(
      id ?? DateTime.now().millisecondsSinceEpoch.remainder(1 << 30),
      title,
      body,
      details,
    );
  }
}

final localNotificationsProvider = Provider<LocalNotifications>(
  (ref) => LocalNotifications(),
);
