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

import 'package:intl/intl.dart';
import 'package:super_green_app/l10n.dart';
import 'package:super_green_app/main/main_navigator_bloc.dart';
import 'package:super_green_app/towelie/towelie_button.dart';
import 'package:super_green_app/towelie/towelie_bloc.dart';

const _id = 'CREATE_PLANT';

class TowelieButtonStartChecklist extends TowelieButton {
  static String get towelieButtonStartChecklist {
    return Intl.message(
      'Start',
      name: 'towelieButtonStartChecklist',
      desc: 'Towelie Button start checklist',
      locale: SGLLocalizations.current.localeName,
    );
  }

  @override
  String get id => _id;

  static Map<String, dynamic> createButton() => TowelieButton.createButton(_id, {
        'title': TowelieButtonStartChecklist.towelieButtonStartChecklist,
      });

  @override
  Stream<TowelieBlocState> buttonPressed(TowelieBlocEventButtonPressed event) async* {
    yield TowelieBlocStateMainNavigation(MainNavigateToCreatePlantEvent());
  }
}
