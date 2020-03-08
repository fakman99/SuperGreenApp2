/*
 * Copyright (C) 2018  SuperGreenLab <towelie@supergreenlab.com>
 * Author: Constantin Clauzel <constantin.clauzel@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'dart:async';
import 'dart:math';

import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:super_green_app/data/rel/rel_db.dart';
import 'package:super_green_app/main/main_navigator_bloc.dart';
import 'package:super_green_app/pages/feeds/box_feed/app_bar/box_feed_app_bar_bloc.dart';
import 'package:super_green_app/pages/feeds/box_feed/app_bar/box_feed_app_bar_page.dart';
import 'package:super_green_app/pages/feeds/box_feed/box_drawer_bloc.dart';
import 'package:super_green_app/pages/feeds/box_feed/box_feed_bloc.dart';
import 'package:super_green_app/pages/feeds/feed/feed_bloc.dart';
import 'package:super_green_app/pages/feeds/feed/feed_page.dart';
import 'package:super_green_app/pages/home/home_navigator_bloc.dart';
import 'package:super_green_app/widgets/fullscreen.dart';
import 'package:super_green_app/widgets/fullscreen_loading.dart';
import 'package:super_green_app/widgets/green_button.dart';
import 'package:url_launcher/url_launcher.dart';

class BoxFeedPage extends StatefulWidget {
  @override
  _BoxFeedPageState createState() => _BoxFeedPageState();
}

enum SpeedDialType {
  general,
  trainings,
}

class _BoxFeedPageState extends State<BoxFeedPage> {
  final _openCloseDial = ValueNotifier<int>(0);
  SpeedDialType _speedDialType = SpeedDialType.general;
  bool _speedDialOpen = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_speedDialOpen) {
          _openCloseDial.value = Random().nextInt(1 << 32);
          return false;
        }
        return true;
      },
      child: BlocBuilder<BoxFeedBloc, BoxFeedBlocState>(
        bloc: BlocProvider.of<BoxFeedBloc>(context),
        builder: (BuildContext context, BoxFeedBlocState state) {
          Widget body;
          if (_speedDialOpen) {
            body = Stack(
              children: <Widget>[
                _renderFeed(context, state),
                _renderOverlay(context),
              ],
            );
          } else {
            body = Stack(
              children: <Widget>[
                _renderFeed(context, state),
              ],
            );
          }

          return Scaffold(
              drawer: Drawer(child: this._drawerContent(context, state)),
              body: AnimatedSwitcher(
                  child: body, duration: Duration(milliseconds: 200)),
              floatingActionButton: state is BoxFeedBlocStateBoxLoaded
                  ? _renderSpeedDial(context, state)
                  : null);
        },
      ),
    );
  }

  SpeedDial _renderSpeedDial(
      BuildContext context, BoxFeedBlocStateBoxLoaded state) {
    return SpeedDial(
      tooltip: 'Speed Dial',
      heroTag: 'speed-dial-hero-tag',
      marginBottom: 10,
      animationSpeed: 50,
      curve: Curves.bounceIn,
      backgroundColor: Color(0xff3bb30b),
      animatedIcon: AnimatedIcons.menu_close,
      animatedIconTheme: IconThemeData(size: 22.0),
      overlayOpacity: 0.8,
      openCloseDial: _openCloseDial,
      closeManually: true,
      onOpen: () {
        setState(() {
          _speedDialType = SpeedDialType.general;
          _speedDialOpen = true;
        });
      },
      onClose: () {
        setState(() {
          _speedDialOpen = false;
        });
      },
      children: _speedDialType == SpeedDialType.general
          ? _renderGeneralSpeedDials(context, state)
          : _renderTrimSpeedDials(context, state),
    );
  }

  List<SpeedDialChild> _renderTrimSpeedDials(
      BuildContext context, BoxFeedBlocStateBoxLoaded state) {
    return [
      SpeedDialChild(
          child: SvgPicture.asset('assets/feed_card/icon_none.svg'),
          label: 'None',
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
          onTap: () {
            setState(() {
              _speedDialType = SpeedDialType.general;
            });
          }),
      _renderSpeedDialChild(
          'Defoliation',
          'assets/feed_card/icon_defoliation.svg',
          _onSpeedDialSelected(
              context,
              ({pushAsReplacement = false}) =>
                  MainNavigateToFeedDefoliationFormEvent(state.box,
                      pushAsReplacement: pushAsReplacement))),
      _renderSpeedDialChild(
          'Topping',
          'assets/feed_card/icon_topping.svg',
          _onSpeedDialSelected(
              context,
              ({pushAsReplacement = false}) =>
                  MainNavigateToFeedToppingFormEvent(state.box,
                      pushAsReplacement: pushAsReplacement))),
      _renderSpeedDialChild(
          'Fimming',
          'assets/feed_card/icon_fimming.svg',
          _onSpeedDialSelected(
              context,
              ({pushAsReplacement = false}) =>
                  MainNavigateToFeedFimmingFormEvent(state.box,
                      pushAsReplacement: pushAsReplacement))),
      _renderSpeedDialChild(
          'Bending',
          'assets/feed_card/icon_bending.svg',
          _onSpeedDialSelected(
              context,
              ({pushAsReplacement = false}) =>
                  MainNavigateToFeedBendingFormEvent(state.box,
                      pushAsReplacement: pushAsReplacement))),
    ];
  }

  List<SpeedDialChild> _renderGeneralSpeedDials(
      BuildContext context, BoxFeedBlocStateBoxLoaded state) {
    return [
      SpeedDialChild(
          child: SvgPicture.asset('assets/feed_card/icon_training.svg'),
          label: 'Plant training',
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
          onTap: () {
            setState(() {
              _speedDialType = SpeedDialType.trainings;
            });
          }),
      _renderSpeedDialChild(
          'Video/pic note',
          'assets/feed_card/icon_media.svg',
          _onSpeedDialSelected(
              context,
              ({pushAsReplacement = false}) => MainNavigateToFeedMediaFormEvent(
                  state.box,
                  pushAsReplacement: pushAsReplacement))),
      _renderSpeedDialChild(
          'Watering',
          'assets/feed_card/icon_watering.svg',
          _onSpeedDialSelected(
              context,
              ({pushAsReplacement = false}) => MainNavigateToFeedWaterFormEvent(
                  state.box,
                  pushAsReplacement: pushAsReplacement))),
      _renderSpeedDialChild(
          'Stretch control',
          'assets/feed_card/icon_dimming.svg',
          _onSpeedDialSelected(
              context,
              ({pushAsReplacement = false}) => MainNavigateToFeedLightFormEvent(
                  state.box,
                  pushAsReplacement: pushAsReplacement))),
      _renderSpeedDialChild(
          'Ventilation control',
          'assets/feed_card/icon_blower.svg',
          _onSpeedDialSelected(
              context,
              ({pushAsReplacement = false}) =>
                  MainNavigateToFeedVentilationFormEvent(state.box,
                      pushAsReplacement: pushAsReplacement))),
      _renderSpeedDialChild(
          'Veg/Bloom',
          'assets/feed_card/icon_schedule.svg',
          _onSpeedDialSelected(
              context,
              ({pushAsReplacement = false}) =>
                  MainNavigateToFeedScheduleFormEvent(state.box,
                      pushAsReplacement: pushAsReplacement))),
    ];
  }

  SpeedDialChild _renderSpeedDialChild(
      String label, String icon, void Function() navigateTo) {
    return SpeedDialChild(
      child: SvgPicture.asset(icon),
      label: label,
      labelStyle: TextStyle(fontWeight: FontWeight.bold),
      onTap: navigateTo,
    );
  }

  void Function() _onSpeedDialSelected(BuildContext context,
      MainNavigatorEvent Function({bool pushAsReplacement}) navigatorEvent) {
    return () {
      _openCloseDial.value = Random().nextInt(1 << 32);
      BlocProvider.of<MainNavigatorBloc>(context)
          .add(MainNavigateToTipEvent(navigatorEvent(pushAsReplacement: true)));
    };
  }

  Widget _renderFeed(BuildContext context, BoxFeedBlocState state) {
    if (state is BoxFeedBlocStateBoxLoaded) {
      return BlocProvider(
        key: Key('feed'),
        create: (context) => FeedBloc(state.box.feed),
        child: FeedPage(
          bottomPadding: true,
          title: '',
          appBarHeight: 300,
          color: Colors.cyan,
          appBar: _renderAppBar(context, state),
        ),
      );
    } else if (state is BoxFeedBlocStateNoBox) {
      return Fullscreen(
          title: 'No box yet.',
          childFirst: false,
          child: GreenButton(
              title: 'Create Box',
              onPressed: () {
                BlocProvider.of<MainNavigatorBloc>(context)
                    .add(MainNavigateToNewBoxInfosEvent());
              }));
    }
    return FullscreenLoading(title: 'Box loading...');
  }

  Widget _renderOverlay(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return InkWell(
          onTap: () {
            _openCloseDial.value = Random().nextInt(1 << 32);
          },
          child: Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              color: Colors.white60),
        );
      },
    );
  }

  Widget _drawerContent(BuildContext context, BoxFeedBlocState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          height: 120,
          child: DrawerHeader(
              child: Row(children: <Widget>[
            SizedBox(
              width: 40,
              height: 40,
              child: SvgPicture.asset("assets/super_green_lab_vertical.svg"),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text('Box list',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ])),
        ),
        Expanded(
          child: _boxList(context, state),
        ),
        Divider(),
        Container(
            child: Align(
                alignment: FractionalOffset.bottomCenter,
                child: Container(
                    child: Column(
                  children: <Widget>[
                    ListTile(
                        leading: Icon(Icons.add_circle),
                        title: Text('Add new box'),
                        onTap: () => _onAddBox(context)),
                  ],
                ))))
      ],
    );
  }

  Widget _boxList(BuildContext context, BoxFeedBlocState boxFeedState) {
    return BlocBuilder<BoxDrawerBloc, BoxDrawerBlocState>(
      bloc: BlocProvider.of<BoxDrawerBloc>(context),
      condition: (previousState, state) =>
          state is BoxDrawerBlocStateLoadingBoxList ||
          state is BoxDrawerBlocStateBoxListUpdated,
      builder: (BuildContext context, BoxDrawerBlocState state) {
        Widget content;
        if (state is BoxDrawerBlocStateLoadingBoxList) {
          content = FullscreenLoading(title: 'Loading..');
        } else if (state is BoxDrawerBlocStateBoxListUpdated) {
          List<Box> boxes = state.boxes;
          content = ListView(
            children: boxes.map((b) {
              Widget item = ListTile(
                leading: (boxFeedState is BoxFeedBlocStateBoxLoaded &&
                        boxFeedState.box.id == b.id)
                    ? Icon(
                        Icons.check_box,
                        color: Colors.green,
                      )
                    : Icon(Icons.crop_square),
                title: Text(b.name),
                onTap: () => _selectBox(context, b),
              );
              try {
                int nOthers = state.hasPending
                    .where((e) => e.id == b.feed)
                    .map((e) => e.nNew)
                    .reduce((a, e) => a + e);
                if (nOthers != null && nOthers > 0) {
                  item = Stack(
                    children: [
                      item,
                      _renderBadge(nOthers),
                    ],
                  );
                }
              } catch (e) {}
              return item;
            }).toList(),
          );
        }
        return AnimatedSwitcher(
          duration: Duration(milliseconds: 200),
          child: content,
        );
      },
    );
  }

  Widget _renderBadge(int n) {
    return Positioned(
      top: 12,
      right: 10,
      child: Container(
        padding: EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(15),
        ),
        constraints: BoxConstraints(
          minWidth: 30,
          minHeight: 30,
        ),
        child: Text(
          '$n',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _selectBox(BuildContext context, Box box) {
    //ignore: close_sinks
    HomeNavigatorBloc navigatorBloc =
        BlocProvider.of<HomeNavigatorBloc>(context);
    Navigator.pop(context);
    Timer(Duration(milliseconds: 250),
        () => navigatorBloc.add(HomeNavigateToBoxFeedEvent(box)));
  }

  void _onAddBox(BuildContext context) {
    BlocProvider.of<MainNavigatorBloc>(context)
        .add(MainNavigateToNewBoxInfosEvent());
  }

  Widget _renderAppBar(BuildContext context, BoxFeedBlocStateBoxLoaded state) {
    String name = StringUtils.capitalize(state.box.name);

    Widget graphBody;
    if (state.box.device != null) {
      graphBody = Stack(children: [_renderGraphs(context, state)]);
    } else {
      graphBody = Stack(children: [
        _renderGraphs(context, state),
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: Colors.white.withAlpha(190)),
          child: Fullscreen(
            fontSize: 18,
            fontWeight: FontWeight.normal,
            title: 'Monitoring feature\nrequires an SGL controller',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                GreenButton(
                  title: 'SHOP NOW',
                  onPressed: () {
                    launch('https://www.supergreenlab.com');
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child:
                      Text('or', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                GreenButton(
                  title: 'DIY NOW',
                  onPressed: () {
                    launch('https://github.com/supergreenlab');
                  },
                ),
              ],
            ),
            childFirst: false,
          ),
        ),
      ]);
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 64.0, top: 12.0),
            child: Text(
              name,
              style: TextStyle(
                  color: Color(0xff505050),
                  fontSize: 25.0,
                  fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 200), child: graphBody),
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderGraphs(context, state) {
    return BlocProvider(
      create: (context) => BoxFeedAppBarBloc(state.box),
      child: BoxFeedAppBarPage(),
    );
  }
}