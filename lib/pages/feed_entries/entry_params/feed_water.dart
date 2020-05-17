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

import 'dart:convert';

import 'package:equatable/equatable.dart';

class FeedWaterParams extends Equatable {
  final double volume;
  final bool tooDry;
  final bool nutrient;

  FeedWaterParams(this.volume, this.tooDry, this.nutrient);

  static FeedWaterParams fromJSON(String json) {
    Map<String, dynamic> map = JsonDecoder().convert(json);
    return FeedWaterParams(map['volume'], map['tooDry'], map['nutrient']);
  }

  static Map<String, dynamic> toJSON(FeedWaterParams p) {
    return {'volume': p.volume, 'tooDry': p.tooDry, 'nutrient': p.nutrient};
  }

  @override
  List<Object> get props => [volume, tooDry, nutrient];
}
