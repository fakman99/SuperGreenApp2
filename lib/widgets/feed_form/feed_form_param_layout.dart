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
import 'package:super_green_app/widgets/section_title.dart';

class FeedFormParamLayout extends StatelessWidget {
  final Widget child;
  final String title;
  final String icon;
  final Color titleBackgroundColor;
  final Color titleColor;
  final bool largeTitle;

  FeedFormParamLayout(
      {@required this.child,
      @required this.icon,
      @required this.title,
      this.titleBackgroundColor,
      this.titleColor,
      this.largeTitle=false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionTitle(
          title: title,
          icon: icon,
          backgroundColor: titleBackgroundColor,
          titleColor: titleColor,
          large: largeTitle,
        ),
        this.child,
      ],
    );
  }
}
