import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:keyboard_visibility/keyboard_visibility.dart';
import 'package:super_green_app/l10n.dart';
import 'package:super_green_app/l10n/common.dart';
import 'package:super_green_app/main/main_navigator_bloc.dart';
import 'package:super_green_app/pages/settings/devices/edit_config/settings_device_bloc.dart';
import 'package:super_green_app/widgets/appbar.dart';
import 'package:super_green_app/widgets/fullscreen.dart';
import 'package:super_green_app/widgets/fullscreen_loading.dart';
import 'package:super_green_app/widgets/green_button.dart';
import 'package:super_green_app/widgets/section_title.dart';
import 'package:super_green_app/widgets/textfield.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsDevicePage extends StatefulWidget {
  static String get settingsDevicePageLoading {
    return Intl.message(
      'Refreshing..',
      name: 'settingsDevicePageLoading',
      desc: 'Loading screen while refreshing parameters',
      locale: SGLLocalizations.current.localeName,
    );
  }

  static String settingsDevicePageControllerRefreshed(String name) {
    return Intl.message(
      'Controller $name refreshed!',
      args: [name],
      name: 'settingsDevicePageControllerRefreshed',
      desc: 'Controller params refreshed confirmation text',
      locale: SGLLocalizations.current.localeName,
    );
  }

  static String settingsDevicePageControllerDone(String name) {
    return Intl.message(
      'Controller $name updated!',
      args: [name],
      name: 'settingsDevicePageControllerDone',
      desc: 'Controller updated confirmation text',
      locale: SGLLocalizations.current.localeName,
    );
  }

  static String get settingsDevicePageControllerNameSection {
    return Intl.message(
      'Controller name',
      name: 'settingsDevicePageControllerNameSection',
      desc: 'Controller name input section',
      locale: SGLLocalizations.current.localeName,
    );
  }

  static String get settingsDevicePageControllerSettingsSection {
    return Intl.message(
      'Settings',
      name: 'settingsDevicePageControllerSettingsSection',
      desc: 'Controller name input section',
      locale: SGLLocalizations.current.localeName,
    );
  }

  static String get settingsDevicePageWifiSettingsSection {
    return Intl.message(
      'Wifi config',
      name: 'settingsDevicePageWifiSettingsSection',
      desc: 'Wifi settings button',
      locale: SGLLocalizations.current.localeName,
    );
  }

  static String get settingsDevicePageWifiSettingsLabel {
    return Intl.message(
      'Change your controller\'s wifi config',
      name: 'settingsDevicePageWifiSettingsLabel',
      desc: 'Wifi settings button label',
      locale: SGLLocalizations.current.localeName,
    );
  }

  static String get settingsDevicePageWifiConfigSuccess {
    return Intl.message(
      'Wifi config changed successfully',
      name: 'settingsDevicePageWifiConfigSuccess',
      desc: 'Wifi config successful message',
      locale: SGLLocalizations.current.localeName,
    );
  }

  static String get settingsDevicePageWifiConfigFailed {
    return Intl.message(
      'Wifi config change failed',
      name: 'settingsDevicePageWifiConfigFailed',
      desc: 'Wifi config failed message',
      locale: SGLLocalizations.current.localeName,
    );
  }

  @override
  _SettingsDevicePageState createState() => _SettingsDevicePageState();
}

class _SettingsDevicePageState extends State<SettingsDevicePage> {
  TextEditingController _nameController;

  KeyboardVisibilityNotification _keyboardVisibility = KeyboardVisibilityNotification();

  int _listener;

  bool _keyboardVisible = false;

  @protected
  void initState() {
    super.initState();
    _listener = _keyboardVisibility.addNewListener(
      onChange: (bool visible) {
        setState(() {
          _keyboardVisible = visible;
        });
        if (!_keyboardVisible) {
          FocusScopeNode currentFocus = FocusScope.of(context);

          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener(
      cubit: BlocProvider.of<SettingsDeviceBloc>(context),
      listener: (BuildContext context, SettingsDeviceBlocState state) async {
        if (state is SettingsDeviceBlocStateLoaded) {
          _nameController = TextEditingController(text: state.device.name);
        } else if (state is SettingsDeviceBlocStateDone) {
          Timer(const Duration(milliseconds: 2000), () {
            BlocProvider.of<MainNavigatorBloc>(context).add(MainNavigatorActionPop(mustPop: true));
          });
        }
      },
      child: BlocBuilder<SettingsDeviceBloc, SettingsDeviceBlocState>(
          cubit: BlocProvider.of<SettingsDeviceBloc>(context),
          builder: (BuildContext context, SettingsDeviceBlocState state) {
            Widget body;
            if (state is SettingsDeviceBlocStateLoading) {
              body = FullscreenLoading(
                title: CommonL10N.loading,
              );
            } else if (state is SettingsDeviceBlocStateRefreshing) {
              body = FullscreenLoading(
                percent: state.percent,
                title: SettingsDevicePage.settingsDevicePageLoading,
              );
            } else if (state is SettingsDeviceBlocStateRefreshed) {
              body = _renderRefreshDone(state);
            } else if (state is SettingsDeviceBlocStateDone) {
              body = _renderDone(state);
            } else if (state is SettingsDeviceBlocStateLoaded) {
              body = _renderForm(context, state);
            }
            return WillPopScope(
              onWillPop: () async {
                return await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(CommonL10N.unsavedChangeDialogTitle),
                        content: Text(CommonL10N.unsavedChangeDialogBody),
                        actions: <Widget>[
                          FlatButton(
                            onPressed: () {
                              Navigator.pop(context, false);
                            },
                            child: Text(CommonL10N.no),
                          ),
                          FlatButton(
                            onPressed: () {
                              Navigator.pop(context, true);
                            },
                            child: Text(CommonL10N.yes),
                          ),
                        ],
                      );
                    });
              },
              child: Scaffold(
                  appBar: SGLAppBar(
                    '🤖',
                    fontSize: 40,
                    backgroundColor: Color(0xff0b6ab3),
                    titleColor: Colors.white,
                    iconColor: Colors.white,
                    hideBackButton: state is SettingsDeviceBlocStateDone,
                  ),
                  backgroundColor: Colors.white,
                  body: AnimatedSwitcher(duration: Duration(milliseconds: 200), child: body)),
            );
          }),
    );
  }

  Widget _renderRefreshDone(SettingsDeviceBlocStateRefreshed state) {
    String subtitle = SettingsDevicePage.settingsDevicePageControllerRefreshed(_nameController.value.text);
    return Fullscreen(
        title: CommonL10N.done, subtitle: subtitle, child: Icon(Icons.done, color: Color(0xff0bb354), size: 100));
  }

  Widget _renderDone(SettingsDeviceBlocStateDone state) {
    String subtitle = SettingsDevicePage.settingsDevicePageControllerDone(_nameController.value.text);
    return Fullscreen(
        title: CommonL10N.done, subtitle: subtitle, child: Icon(Icons.done, color: Color(0xff0bb354), size: 100));
  }

  Widget _renderForm(BuildContext context, SettingsDeviceBlocStateLoaded state) {
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            children: <Widget>[
              SectionTitle(
                title: SettingsDevicePage.settingsDevicePageControllerNameSection,
                icon: 'assets/box_setup/icon_controller.svg',
                backgroundColor: Color(0xff0b6ab3),
                titleColor: Colors.white,
                elevation: 5,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 24.0),
                child: SGLTextField(
                    hintText: 'Ex: SuperGreenController',
                    controller: _nameController,
                    onChanged: (_) {
                      setState(() {});
                    }),
              ),
              SectionTitle(
                title: SettingsDevicePage.settingsDevicePageControllerSettingsSection,
                icon: 'assets/box_setup/icon_controller.svg',
                backgroundColor: Color(0xff0b6ab3),
                titleColor: Colors.white,
                elevation: 5,
              ),
              ListTile(
                leading: SvgPicture.asset('assets/feed_form/icon_wifi.svg'),
                trailing: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: SvgPicture.asset('assets/settings/icon_go.svg'),
                ),
                title: Text(SettingsDevicePage.settingsDevicePageWifiSettingsSection),
                subtitle: Text(SettingsDevicePage.settingsDevicePageWifiSettingsLabel),
                onTap: () {
                  BlocProvider.of<MainNavigatorBloc>(context)
                      .add(MainNavigateToDeviceWifiEvent(state.device, futureFn: (Future future) async {
                    dynamic error = await future;
                    if (error == null) {
                      return;
                    }
                    if (error != true) {
                      await Fluttertoast.showToast(msg: SettingsDevicePage.settingsDevicePageWifiConfigSuccess);
                    } else {
                      await Fluttertoast.showToast(msg: SettingsDevicePage.settingsDevicePageWifiConfigFailed);
                    }
                  }));
                },
              ),
              ListTile(
                leading: SvgPicture.asset('assets/box_setup/icon_box.svg'),
                trailing: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: SvgPicture.asset('assets/settings/icon_go.svg'),
                ),
                title: Text('View slots'),
                subtitle: Text('Tap to view this controller\'s box slots'),
                onTap: () {
                  BlocProvider.of<MainNavigatorBloc>(context).add(MainNavigateToSelectDeviceBoxEvent(state.device));
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  leading: SvgPicture.asset('assets/box_setup/icon_controller.svg'),
                  trailing: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: SvgPicture.asset('assets/settings/icon_go.svg'),
                  ),
                  title: Text('Refresh params'),
                  subtitle: Text('Use this button if there were changes made to the controller outside the app.'),
                  onTap: () {
                    BlocProvider.of<SettingsDeviceBloc>(context).add(SettingsDeviceBlocEventRefresh());
                  },
                ),
              ),
              SectionTitle(
                title: 'Red zone',
                icon: 'assets/box_setup/icon_controller.svg',
                backgroundColor: Colors.red,
                titleColor: Colors.white,
                elevation: 5,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  leading: SvgPicture.asset('assets/settings/icon_warning.svg'),
                  trailing: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: SvgPicture.asset('assets/settings/icon_go.svg'),
                  ),
                  title: Text('Access admin'),
                  subtitle: Text(
                      'Open the controller\'s admin interface. Make sure you know what you\'re doing before going there.'),
                  onTap: () {
                    launch('http://${state.device.ip}/fs/app.html');
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  leading: SvgPicture.asset('assets/settings/icon_upgrade.svg'),
                  trailing: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: SvgPicture.asset('assets/settings/icon_go.svg'),
                  ),
                  title: Text('Firmware upgrade'),
                  subtitle:
                      Text('Check and perform controller firmware upgrade. Requires the controller to be reachable.'),
                  onTap: () {
                    BlocProvider.of<MainNavigatorBloc>(context)
                        .add(MainNavigateToSettingsUpgradeDevice(state.device, futureFn: (future) async {
                      dynamic ret = await future;
                      if (ret is bool && ret == true) {
                        BlocProvider.of<SettingsDeviceBloc>(context).add(SettingsDeviceBlocEventRefresh(delete: true));
                      }
                    }));
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, right: 8.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: GreenButton(
              title: 'UPDATE CONTROLLER',
              onPressed: _nameController.value.text != '' ? () => _handleInput(context) : null,
            ),
          ),
        ),
      ],
    );
  }

  void _handleInput(BuildContext context) async {
    BlocProvider.of<SettingsDeviceBloc>(context).add(SettingsDeviceBlocEventUpdate(
      _nameController.text,
    ));
  }

  @override
  void dispose() {
    _keyboardVisibility.removeListener(_listener);
    _nameController.dispose();
    super.dispose();
  }
}
