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
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:super_green_app/data/rel/rel_db.dart';

abstract class FeedCareCommonCardBlocEvent extends Equatable {}

class FeedCareCommonCardBlocEventInit extends FeedCareCommonCardBlocEvent {
  @override
  List<Object> get props => [];
}

class FeedCareCommonCardBlocState extends Equatable {
  final Feed feed;
  final FeedEntry feedEntry;
  final Map<String, dynamic> params;
  final List<FeedMedia> beforeMedias;
  final List<FeedMedia> afterMedias;

  FeedCareCommonCardBlocState(this.feed, this.feedEntry, this.params,
      this.beforeMedias, this.afterMedias);

  @override
  List<Object> get props => [
        feed,
        feedEntry,
        params,
        beforeMedias,
        afterMedias,
      ];
}

class FeedCareCommonCardBloc
    extends Bloc<FeedCareCommonCardBlocEvent, FeedCareCommonCardBlocState> {
  final Feed _feed;
  final FeedEntry _feedEntry;
  final Map<String, dynamic> _params = {};

  final List<FeedMedia> _beforeMedias = [];
  final List<FeedMedia> _afterMedias = [];

  @override
  FeedCareCommonCardBlocState get initialState => FeedCareCommonCardBlocState(
      _feed, _feedEntry, {}, [], []);

  FeedCareCommonCardBloc(this._feed, this._feedEntry) {
    _params.addAll(JsonDecoder().convert(_feedEntry.params));
    add(FeedCareCommonCardBlocEventInit());
  }

  @override
  Stream<FeedCareCommonCardBlocState> mapEventToState(
      FeedCareCommonCardBlocEvent event) async* {
    if (event is FeedCareCommonCardBlocEventInit) {
      RelDB db = RelDB.get();
      List<FeedMedia> medias = await db.feedsDAO.getFeedMedias(_feedEntry.id);
      _beforeMedias.addAll(medias.where((m) {
        final Map<String, dynamic> params = JsonDecoder().convert(m.params);
        return params['before'];
      }));
      _afterMedias.addAll(medias.where((m) {
        final Map<String, dynamic> params = JsonDecoder().convert(m.params);
        return !params['before'];
      }));
      yield FeedCareCommonCardBlocState(
          _feed, _feedEntry, _params, _beforeMedias, _afterMedias);
    }
  }
}