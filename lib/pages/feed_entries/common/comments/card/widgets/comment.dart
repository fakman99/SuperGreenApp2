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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:super_green_app/data/api/backend/feeds/models/comments.dart';

class SmallCommentView extends StatelessWidget {
  final Comment comment;

  const SmallCommentView({Key key, this.comment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: '**${comment.from}** ${comment.text}',
      styleSheet:
          MarkdownStyleSheet(p: TextStyle(color: Colors.black, fontSize: 16)),
    );
  }
}

class CommentView extends StatelessWidget {
  final Comment comment;

  const CommentView({Key key, this.comment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(comment.text);
  }
}
