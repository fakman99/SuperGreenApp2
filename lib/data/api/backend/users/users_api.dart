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
import 'package:http/http.dart';
import 'package:super_green_app/data/api/backend/backend_api.dart';
import 'package:super_green_app/data/kv/app_db.dart';
import 'package:super_green_app/data/logger/logger.dart';

class User extends Equatable {
  final String id;
  final String nickname;

  User({this.id, this.nickname});

  factory User.fromMap(Map<String, dynamic> userMap) {
    return User(id: userMap['id'], nickname: userMap['nickname']);
  }

  @override
  List<Object> get props => [id, nickname];
}

class UsersAPI {
  bool get loggedIn => AppDB().getAppData().jwt != null;

  Future login(String nickname, String password) async {
    Response resp =
        await BackendAPI().apiClient.post('${BackendAPI().serverHost}/login',
            headers: {'Content-Type': 'application/json'},
            body: JsonEncoder().convert({
              'handle': nickname,
              'password': password,
            }));
    if (resp.statusCode ~/ 100 != 2) {
      Logger.log(resp.body);
      throw 'Access denied';
    }
    AppDB().setJWT(resp.headers['x-sgl-token']);
  }

  Future createUser(String nickname, String password) async {
    Response resp =
        await BackendAPI().apiClient.post('${BackendAPI().serverHost}/user',
            headers: {
              'Content-Type': 'application/json',
            },
            body: JsonEncoder().convert({
              'nickname': nickname,
              'password': password,
            }));
    if (resp.statusCode ~/ 100 != 2) {
      Logger.log(resp.body);
      throw 'createUser failed';
    }
  }

  Future<User> me() async {
    Response resp = await BackendAPI()
        .apiClient
        .get('${BackendAPI().serverHost}/users/me', headers: {
      'Content-Type': 'application/json',
      'Authentication': 'Bearer ${AppDB().getAppData().jwt}',
    });
    if (resp.statusCode ~/ 100 != 2) {
      Logger.log(resp.body);
      throw 'me failed';
    }
    Map<String, dynamic> userMap = JsonDecoder().convert(resp.body);
    return User.fromMap(userMap);
  }
}
