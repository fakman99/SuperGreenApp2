import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:super_green_app/main/main_navigator_bloc.dart';

abstract class LocalNotificationBlocEvent extends Equatable {}

class LocalNotificationBlocEventInit extends LocalNotificationBlocEvent {
  @override
  List<Object> get props => [];
}

class LocalNotificationBlocEventReminder extends LocalNotificationBlocEvent {
  final int id;
  final int afterMinutes;
  final String title;
  final String body;

  LocalNotificationBlocEventReminder(
      this.id, this.afterMinutes, this.title, this.body);

  @override
  List<Object> get props => [];
}

class LocalNotificationBlocEventNotificationReceived
    extends LocalNotificationBlocEvent {
  final int id;
  final String title;
  final String body;
  final String payload;

  LocalNotificationBlocEventNotificationReceived(this.id, this.title, this.body, this.payload);

  @override
  List<Object> get props => [];
}

class LocalNotificationBlocEventNotificationSelected
    extends LocalNotificationBlocEvent {
  final String payload;

  LocalNotificationBlocEventNotificationSelected(this.payload);

  @override
  List<Object> get props => [];
}

abstract class LocalNotificationBlocState extends Equatable {}

class LocalNotificationBlocStateInit extends LocalNotificationBlocState {
  @override
  List<Object> get props => [];
}

class LocalNotificationBlocStateNotification extends LocalNotificationBlocState {
  final int id;
  final String title;
  final String body;
  final String payload;

  LocalNotificationBlocStateNotification(this.id, this.title, this.body, this.payload);

  @override
  List<Object> get props => [];
}

class LocalNotificationBlocStateMainNavigation
    extends LocalNotificationBlocState {
  final int rand = Random().nextInt(1 << 32);
  final MainNavigatorEvent mainNavigatorEvent;

  LocalNotificationBlocStateMainNavigation(this.mainNavigatorEvent);

  @override
  List<Object> get props => [rand, mainNavigatorEvent];
}

class LocalNotificationBloc
    extends Bloc<LocalNotificationBlocEvent, LocalNotificationBlocState> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  LocalNotificationBloc() {
    add(LocalNotificationBlocEventInit());
  }

  @override
  LocalNotificationBlocState get initialState =>
      LocalNotificationBlocStateInit();

  @override
  Stream<LocalNotificationBlocState> mapEventToState(
      LocalNotificationBlocEvent event) async* {
    if (event is LocalNotificationBlocEventInit) {
      await init();
    } else if (event is LocalNotificationBlocEventReminder) {
      await this.reminderNotification(
          event.id, event.afterMinutes, event.title, event.body);
    } else if (event is LocalNotificationBlocEventNotificationReceived) {
      yield LocalNotificationBlocStateNotification(event.id, event.title, event.body, event.payload);
    } else if (event is LocalNotificationBlocEventNotificationSelected) {

    }
  }

  Future init() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = IOSInitializationSettings(
        requestSoundPermission: false,
        requestBadgePermission: false,
        requestAlertPermission: false,
        onDidReceiveLocalNotification: _onDidReceiveLocalNotification);
    var initializationSettings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: _onSelectNotification);
  }

  Future _onDidReceiveLocalNotification(
      int id, String title, String body, String payload) async {
    print('onDidReceiveLocalNotification');
    add(LocalNotificationBlocEventNotificationReceived(id, title, body, payload));
    if (payload != null) {
      print('notification payload: $id $title $body $payload');
    }
  }

  Future _onSelectNotification(String payload) async {
    print('onSelectNotification');
    add(LocalNotificationBlocEventNotificationSelected(payload));
    if (payload != null) {
      print('notification payload: $payload');
    }
  }

  Future<bool> checkPermissions() async {
    return flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
        true;
  }

  Future reminderNotification(
      int id, int afterMinutes, String title, String body) async {
    if (!await this.checkPermissions()) {
      return;
    }

    var scheduledNotificationDateTime =
        DateTime.now().add(Duration(minutes: afterMinutes));
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'REMINDERS',
        'Towelie\'s reminders',
        'Towelie can help you not forget anything about your grow.');
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    NotificationDetails platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.schedule(id, title, body,
        scheduledNotificationDateTime, platformChannelSpecifics,
        androidAllowWhileIdle: true);
  }
}