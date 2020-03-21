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

import 'package:super_green_app/data/rel/rel_db.dart';
import 'package:super_green_app/l10n.dart';
import 'package:super_green_app/towelie/towelie_action_help.dart';
import 'package:super_green_app/towelie/towelie_bloc.dart';

class TowelieActionHelpFormMeasure extends TowelieActionHelp {
  @override
  String get route => '/feed/form/measure';

  @override
  Stream<TowelieBlocState> routeTrigger(TowelieBlocEventRoute event) async* {
    int nMeasures = await RelDB.get().feedsDAO.getNMeasures();
    if (nMeasures == 0) {
      yield TowelieBlocStateHelper(
          event.settings, SGLLocalizations.current.towelieHelperFormMeasure,
          hasNext: true);
    } else if (nMeasures == 1) {
      yield TowelieBlocStateHelper(
          event.settings, SGLLocalizations.current.towelieHelperFormMeasure3,
          hasNext: false);
    }
  }

  @override
  Stream<TowelieBlocState> getNext(TowelieBlocEventHelperNext event) async* {
    int nMeasures = await RelDB.get().feedsDAO.getNMeasures();
    if (nMeasures == 0) {
      yield TowelieBlocStateHelper(
          event.settings, SGLLocalizations.current.towelieHelperFormMeasure2);
    }
  }
}