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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:super_green_app/main/analytics_observer.dart';
import 'package:super_green_app/pages/explorer/explorer_bloc.dart';
import 'package:super_green_app/pages/explorer/explorer_page.dart';
import 'package:super_green_app/pages/feeds/box_feed/box_drawer_bloc.dart';
import 'package:super_green_app/pages/feeds/box_feed/box_feed_bloc.dart';
import 'package:super_green_app/pages/feeds/box_feed/box_feed_page.dart';
import 'package:super_green_app/pages/feeds/sgl_feed/sgl_feed_bloc.dart';
import 'package:super_green_app/pages/feeds/sgl_feed/sgl_feed_page.dart';
import 'package:super_green_app/pages/home/home_bloc.dart';
import 'package:super_green_app/pages/home/home_navigator_bloc.dart';
import 'package:super_green_app/pages/settings/settings_bloc.dart';
import 'package:super_green_app/pages/settings/settings_page.dart';
import 'package:super_green_app/towelie/towelie_bloc.dart';
import 'package:super_green_app/widgets/fullscreen_loading.dart';

final RouteObserver<PageRoute> _analyticsObserver = AnalyticsObserver();

class HomePage extends StatelessWidget {
  final GlobalKey<NavigatorState> _navigatorKey;

  HomePage(this._navigatorKey);

  @override
  Widget build(BuildContext context) {
    return BlocListener<TowelieBloc, TowelieBlocState>(
      listener: (BuildContext context, state) {
        if (state is TowelieBlocStateHomeNavigation) {
          BlocProvider.of<HomeNavigatorBloc>(context)
              .add(state.homeNavigatorEvent);
        }
      },
      child: BlocBuilder<HomeNavigatorBloc, HomeNavigatorState>(
        builder: (context, navigatorState) =>
            BlocBuilder<HomeBloc, HomeBlocState>(builder: (context, state) {
          Widget body;
          Widget navbar;
          if (state is HomeBlocStateInit) {
            body = FullscreenLoading(
              title: 'Loading..',
            );
          } else if (state is HomeBlocStateLoaded) {
            body = Navigator(
              observers: [_analyticsObserver],
              key: _navigatorKey,
              onGenerateRoute: (settings) =>
                  this._onGenerateRoute(context, settings),
            );

            Widget sglIcon = Icon(Icons.feedback);
            try {
              int nSgl = state.hasPending
                  .where((e) => e.id == 1)
                  .map((e) => e.nNew)
                  .reduce((a, e) => a + e);
              if (nSgl != null && nSgl > 0) {
                sglIcon = Stack(
                  children: [
                    sglIcon,
                    _renderBadge(nSgl),
                  ],
                );
              }
            } catch (e) {}
            Widget homeIcon = Icon(Icons.home);
            try {
              int nOthers = state.hasPending
                  .where((e) => e.id != 1)
                  .map((e) => e.nNew)
                  .reduce((a, e) => a + e);
              if (nOthers != null && nOthers > 0) {
                homeIcon = Stack(
                  children: [
                    homeIcon,
                    _renderBadge(nOthers),
                  ],
                );
              }
            } catch (e) {}
            navbar = BottomNavigationBar(
              unselectedItemColor: Colors.black38,
              selectedItemColor: Colors.green,
              onTap: (i) =>
                  this._onNavigationBarItemSelect(context, i, navigatorState),
              elevation: 0,
              currentIndex: navigatorState.index,
              items: [
                BottomNavigationBarItem(
                  icon: sglIcon,
                  title: Text('Towelie'),
                ),
                BottomNavigationBarItem(
                  icon: homeIcon,
                  title: Text('Home'),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.explore),
                  title: Text('Explore'),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  title: Text('Settings'),
                ),
              ],
            );
          }

          return Scaffold(
            bottomNavigationBar: navbar,
            body: AnimatedSwitcher(
                duration: Duration(milliseconds: 200), child: body),
          );
        }),
      ),
    );
  }

  Widget _renderBadge(int n) {
    return Positioned(
      right: 0,
      child: Container(
        padding: EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(7),
        ),
        constraints: BoxConstraints(
          minWidth: 14,
          minHeight: 14,
        ),
        child: Text(
          '$n',
          style: TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _onNavigationBarItemSelect(
      BuildContext context, int i, HomeNavigatorState state) {
    if (i == state.index) return;
    if (i == 0) {
      BlocProvider.of<HomeNavigatorBloc>(context)
          .add(HomeNavigateToSGLFeedEvent());
    } else if (i == 1) {
      BlocProvider.of<HomeNavigatorBloc>(context)
          .add(HomeNavigateToBoxFeedEvent(null));
    } else if (i == 2) {
      BlocProvider.of<HomeNavigatorBloc>(context)
          .add(HomeNavigateToExplorerEvent());
    } else if (i == 3) {
      BlocProvider.of<HomeNavigatorBloc>(context)
          .add(HomeNavigateToSettingsEvent());
    }
  }

  Route<dynamic> _onGenerateRoute(
      BuildContext context, RouteSettings settings) {
    Timer(Duration(seconds: 1), () {
      BlocProvider.of<TowelieBloc>(context)
          .add(TowelieBlocEventRoute(settings));
    });
    if (settings.arguments == null) {
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => BlocProvider(
                create: (context) => SGLFeedBloc(),
                child: SGLFeedPage(),
              ));
    }
    switch (settings.name) {
      case '/feed/sgl':
        return MaterialPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                  create: (context) => SGLFeedBloc(),
                  child: SGLFeedPage(),
                ));
      case '/feed/box':
        return MaterialPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(
                  providers: [
                    BlocProvider<BoxDrawerBloc>(
                        create: (context) => BoxDrawerBloc()),
                    BlocProvider<BoxFeedBloc>(
                      create: (context) => BoxFeedBloc(settings.arguments),
                    )
                  ],
                  child: BoxFeedPage(),
                ));
      case '/explorer':
        return MaterialPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                  create: (context) => ExplorerBloc(),
                  child: ExplorerPage(),
                ));
      case '/settings':
        return MaterialPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                  create: (context) => SettingsBloc(),
                  child: SettingsPage(),
                ));
      default:
        return MaterialPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                  create: (context) => SGLFeedBloc(),
                  child: SGLFeedPage(),
                ));
    }
  }
}