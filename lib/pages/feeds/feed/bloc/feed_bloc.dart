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

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:super_green_app/pages/feeds/feed/bloc/state/feed_entry_state.dart';
import 'package:super_green_app/pages/feeds/feed/bloc/state/feed_state.dart';

abstract class FeedBlocEvent extends Equatable {}

class FeedBlocEventInit extends FeedBlocEvent {
  FeedBlocEventInit() : super();

  @override
  List<Object> get props => [];
}

class FeedBlocEventLoadEntries extends FeedBlocEvent {
  final int n;

  FeedBlocEventLoadEntries(this.n);

  @override
  List<Object> get props => [n];
}

class FeedBlocEventUpdateEntry extends FeedBlocEvent {
  final int index;
  final FeedEntryState entry;

  FeedBlocEventUpdateEntry(this.index, this.entry);

  @override
  List<Object> get props => [index, entry];
}

class FeedBlocEventDeleteFeedEntry extends FeedBlocEvent {
  final int index;

  FeedBlocEventDeleteFeedEntry(this.index);

  @override
  List<Object> get props => [index];
}

class FeedBlocEventEntryVisible extends FeedBlocEvent {
  final int index;

  FeedBlocEventEntryVisible(this.index);

  @override
  List<Object> get props => [index];
}

class FeedBlocEventEntryHidden extends FeedBlocEvent {
  final int index;

  FeedBlocEventEntryHidden(this.index);

  @override
  List<Object> get props => [index];
}

class FeedBlocEventMarkAsRead extends FeedBlocEvent {
  final int index;

  FeedBlocEventMarkAsRead(this.index);

  @override
  List<Object> get props => [index];
}

abstract class FeedBlocState extends Equatable {}

class FeedBlocStateInit extends FeedBlocState {
  FeedBlocStateInit() : super();

  @override
  List<Object> get props => [];
}

class FeedBlocStateFeedLoaded extends FeedBlocState {
  final FeedState feed;

  FeedBlocStateFeedLoaded(this.feed);

  @override
  List<Object> get props => [feed];
}

class FeedBlocStateEntriesLoaded extends FeedBlocState {
  final List<FeedEntryState> entries;
  final bool eof;

  FeedBlocStateEntriesLoaded(this.entries, this.eof);

  @override
  List<Object> get props => [entries, eof];
}

class FeedBlocStateAddEntry extends FeedBlocState {
  final int index;
  final FeedEntryState entry;

  FeedBlocStateAddEntry(this.index, this.entry);

  @override
  List<Object> get props => [index, entry];
}

class FeedBlocStateUpdateEntry extends FeedBlocState {
  final int index;
  final FeedEntryState entry;

  FeedBlocStateUpdateEntry(this.index, this.entry);

  @override
  List<Object> get props => [index, entry];
}

class FeedBlocStateRemoveEntry extends FeedBlocState {
  final int index;
  final FeedEntryState entry;

  FeedBlocStateRemoveEntry(this.index, this.entry);

  @override
  List<Object> get props => [index, entry];
}

class FeedBloc extends Bloc<FeedBlocEvent, FeedBlocState> {
  FeedBlocProvider provider;
  List<FeedEntryState> entries = [];

  FeedBloc(this.provider) {
    add(FeedBlocEventInit());
    add(FeedBlocEventLoadEntries(10));
  }

  @override
  FeedBlocState get initialState => FeedBlocStateInit();

  @override
  Stream<FeedBlocState> mapEventToState(FeedBlocEvent event) async* {
    if (event is FeedBlocEventInit) {
      await provider.init();
    } else if (event is FeedBlocEventLoadEntries) {
      List<FeedEntryState> fes =
          await provider.loadEntries(event.n, entries.length);
      entries.addAll(fes);
      yield FeedBlocStateEntriesLoaded(entries, entries.length < event.n);
    } else if (event is FeedBlocEventEntryVisible) {
      FeedEntryState e = entries[event.index];
      if (e is FeedEntryStateNotLoaded) {
        FeedEntryLoader loader = provider.loaders[e.type];
        e = await loader.load(e);
        entries[event.index] = e;
        yield FeedBlocStateUpdateEntry(event.index, e);
      }
      provider.startListenEntryChanges(e);
    } else if (event is FeedBlocEventEntryHidden) {
      provider.cancelListenEntryChanges(entries[event.index]);
    } else if (event is FeedBlocEventUpdateEntry) {
      yield FeedBlocStateUpdateEntry(event.index, event.entry);
    } else if (event is FeedBlocEventMarkAsRead) {
      await provider.markAsRead(entries[event.index].feedEntryID);
    }
  }
}

abstract class FeedEntryLoader {
  Future<FeedEntryStateLoaded> load(FeedEntryStateNotLoaded state);
}

abstract class FeedBlocProvider {
  Map<String, FeedEntryLoader> get loaders;
  Future init();
  Future<List<FeedEntryStateNotLoaded>> loadEntries(int n, int offset);
  Future markAsRead(dynamic feedEntryID);
  void startListenEntryChanges(FeedEntryStateLoaded entry);
  void cancelListenEntryChanges(FeedEntryStateLoaded entry);
}