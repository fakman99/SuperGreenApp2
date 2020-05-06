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

import 'package:flutter/material.dart';
import 'package:super_green_app/data/kv/app_db.dart';
import 'package:super_green_app/pages/feed_entries/feed_water/card/feed_water_state.dart';
import 'package:super_green_app/pages/feeds/feed/bloc/feed_bloc_entry_state.dart';
import 'package:super_green_app/widgets/feed_card/feed_card.dart';
import 'package:super_green_app/widgets/feed_card/feed_card_date.dart';
import 'package:super_green_app/widgets/feed_card/feed_card_title.dart';
import 'package:super_green_app/widgets/fullscreen_loading.dart';

class FeedWaterCardPage extends StatelessWidget {
  final Animation animation;
  final FeedEntryState state;

  const FeedWaterCardPage(this.animation, this.state, {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (state is FeedBlocEntryStateLoaded) {
      return _renderLoaded(context, state);
    }
    return _renderLoading(context);
  }

  Widget _renderLoading(BuildContext context) {
    return FeedCard(
      animation: animation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FeedCardTitle(
              'assets/feed_card/icon_watering.svg', 'Watering', state.synced),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FeedCardDate(state.date),
          ),
          Container(
            height: 90,
            alignment: Alignment.center,
            child: FullscreenLoading(),
          ),
        ],
      ),
    );
  }

  Widget _renderLoaded(BuildContext context, FeedBlocEntryStateLoaded state) {
    final FeedWaterState cardState = state.state;
    List<Widget> body = [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Text(
          AppDB().getAppData().freedomUnits == true
              ? '${cardState.volume / 4} gal'
              : '${cardState.volume} L',
          style: TextStyle(
              fontSize: 45,
              fontWeight: FontWeight.w300,
              color: Color(0xff3bb30b)),
        ),
      ),
    ];
    if (cardState.tooDry != null || cardState.nutrient != null) {
      List<Widget> details = [];
      if (cardState.tooDry != null) {
        details.add(Padding(
          padding: const EdgeInsets.all(4.0),
          child: Text(
            'Was Dry: ${cardState.tooDry == true ? 'YES' : 'NO'}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300),
          ),
        ));
      }
      if (cardState.nutrient != null) {
        details.add(
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(
              'With nutes: ${cardState.nutrient == true ? 'YES' : 'NO'}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300),
            ),
          ),
        );
      }
      body.add(Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: details,
      ));
    }
    return FeedCard(
      animation: animation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FeedCardTitle(
              'assets/feed_card/icon_watering.svg', 'Watering', state.synced),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FeedCardDate(state.date),
          ),
          Container(
            height: 90,
            alignment: Alignment.center,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center, children: body),
          ),
        ],
      ),
    );
  }
}
