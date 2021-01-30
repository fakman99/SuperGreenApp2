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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:super_green_app/data/api/backend/backend_api.dart';
import 'package:super_green_app/data/api/backend/feeds/models/comments.dart';
import 'package:super_green_app/data/api/backend/products/models.dart';
import 'package:super_green_app/data/api/backend/users/users_api.dart';
import 'package:super_green_app/main/main_navigator_bloc.dart';
import 'package:super_green_app/pages/feed_entries/common/comments/form/comments_form_bloc.dart';
import 'package:super_green_app/pages/feed_entries/common/comments/form/widgets/comment.dart';
import 'package:super_green_app/pages/feed_entries/common/widgets/user_avatar.dart';
import 'package:super_green_app/widgets/appbar.dart';
import 'package:super_green_app/widgets/fullscreen_loading.dart';

const Map<CommentType, Map<String, String>> commentTypes = {
  CommentType.COMMENT: {
    'name': 'Comment',
    'pic': 'assets/feed_card/icon_comment.png',
    'prompt': 'Type your comment',
  },
  CommentType.TIPS: {
    'name': 'Tips&tricks',
    'pic': 'assets/feed_card/icon_tips.png',
    'prompt': 'Type your tips&tricks',
  },
  CommentType.DIAGNOSIS: {
    'name': 'Diagnosis',
    'pic': 'assets/feed_card/icon_diagnosis.png',
    'prompt': 'Type your diagnosis',
  },
  CommentType.RECOMMEND: {
    'name': 'Recommend',
    'pic': 'assets/feed_card/icon_recommend.png',
    'prompt': 'Type your recommendation',
  },
};

class CommentsFormPage extends StatefulWidget {
  @override
  _CommentsFormPageState createState() => _CommentsFormPageState();
}

class _CommentsFormPageState extends State<CommentsFormPage>
    with TickerProviderStateMixin {
  final List<Comment> comments = [];
  User user;
  bool autoFocus;
  Comment replyTo;
  Comment replyToDisplay;
  List<Product> recommended;

  bool eof = false;

  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();
  final FocusNode inputFocus = FocusNode();
  final ScrollController scrollController = ScrollController();
  final TextEditingController textEditingController = TextEditingController();

  CommentType type = CommentType.COMMENT;

  @override
  Widget build(BuildContext context) {
    return BlocListener<CommentsFormBloc, CommentsFormBlocState>(
      listener: (BuildContext context, CommentsFormBlocState state) {
        if (state is CommentsFormBlocStateLoaded) {
          setState(() {
            this.autoFocus = state.autoFocus;
            this.user = state.user;
            this.eof = state.eof;
            state.comments.forEach((comment) {
              int existsIndex = comments.indexWhere((c) => c.id == comment.id);
              if (existsIndex != -1) {
                setState(() {
                  comments[existsIndex] = comment;
                });
                return;
              }
              insertNewComment(comment);
            });
          });
        } else if (state is CommentsFormBlocStateUpdateComment) {
          int i = comments.indexWhere((c) => c.id == state.commentID);
          if (i != -1) {
            setState(() {
              comments[i] = state.comment;
            });
          }
        } else if (state is CommentsFormBlocStateAddComment) {
          insertNewComment(state.comment);
          if (scrollController.hasClients &&
              scrollController.offset != 0 &&
              state.comment.replyTo == null) {
            Timer(
                Duration(milliseconds: 100),
                () => scrollController.animateTo(0,
                    duration: Duration(milliseconds: 500),
                    curve: Curves.linear));
          }
        } else if (state is CommentsFormBlocStateUser) {
          setState(() {
            this.user = state.user;
          });
        }
      },
      child: BlocBuilder<CommentsFormBloc, CommentsFormBlocState>(
          buildWhen: (CommentsFormBlocState s1, CommentsFormBlocState s2) {
        return !(s2 is CommentsFormBlocStateUpdateComment) &&
            !(s2 is CommentsFormBlocStateAddComment) &&
            !(s2 is CommentsFormBlocStateUser);
      }, builder: (BuildContext context, CommentsFormBlocState state) {
        List<Widget> body;
        if (state is CommentsFormBlocStateInit) {
          body = [FullscreenLoading()];
        } else if (state is CommentsFormBlocStateLoaded) {
          body = [renderLoaded(context)];
        } else if (state is CommentsFormBlocStateLoading) {
          body = [
            renderLoaded(context),
            FullscreenLoading(),
          ];
        }
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: SGLAppBar(
            'Comments',
            backgroundColor: Colors.white,
            titleColor: Colors.black,
            iconColor: Colors.black,
            elevation: 2,
          ),
          body: AnimatedSwitcher(
              duration: Duration(milliseconds: 200),
              child: Stack(
                children: body,
              )),
        );
      }),
    );
  }

  Widget renderLoaded(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
            child: AnimatedList(
          key: listKey,
          controller: scrollController,
          itemBuilder:
              (BuildContext context, int index, Animation<double> animation) {
            if (index >= comments.length) {
              if (eof) {
                return null;
              }
              BlocProvider.of<CommentsFormBloc>(context).add(
                  CommentsFormBlocEventLoadComments(
                      comments.where((c) => c.replyTo == null).length));
              return Container(
                height: 100,
                child: FullscreenLoading(
                  title: 'Loading more comments..',
                  fontSize: 15,
                  size: 25,
                ),
              );
            }
            return FadeTransition(
                opacity: animation,
                child: SizeTransition(
                    sizeFactor: animation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: CommentView(
                        loggedIn: this.user != null,
                        comment: comments[index],
                        first: index == 0,
                        replyTo: () {
                          setState(() {
                            replyTo = comments[index];
                            replyToDisplay = replyTo;
                            if (replyTo.replyTo != null) {
                              replyTo = comments
                                  .firstWhere((c) => c.id == replyTo.replyTo);
                            }
                            inputFocus.requestFocus();
                            type = CommentType.COMMENT;
                            textEditingController.text =
                                '@${replyToDisplay.from} ';
                          });
                        },
                      ),
                    )));
          },
          initialItemCount: eof ? comments.length : comments.length + 1,
        )),
        renderInputContainer(context),
      ],
    );
  }

  Widget renderInputContainer(BuildContext context) {
    if (user == null) {
      return InkWell(
        onTap: () {
          BlocProvider.of<MainNavigatorBloc>(context)
              .add(MainNavigateToSettingsAuth());
        },
        child: Center(
            child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Please login to add a comment',
              style: TextStyle(
                  fontSize: 15.0,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline)),
        )),
      );
    }

    Widget content;

    if (replyTo != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              UserAvatar(
                icon: (replyToDisplay ?? replyTo).pic,
                size: 25,
              ),
              Text(
                'Replying to ',
                style: TextStyle(
                  color: Color(0xff474747),
                  fontSize: 16,
                ),
              ),
              Text(
                (replyToDisplay ?? replyTo).from,
                style: TextStyle(
                  color: Color(0xff474747),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    type = CommentType.COMMENT;
                    FocusScope.of(context).unfocus();
                    this.replyTo = null;
                    this.replyToDisplay = null;
                  });
                },
                icon: Icon(Icons.close, size: 15),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              (replyToDisplay ?? replyTo).text,
              overflow: TextOverflow.fade,
              maxLines: 3,
              style: TextStyle(
                color: Color(0xff474747),
                fontSize: 15,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      );
    } else if (type == CommentType.COMMENT) {
      content = Column(children: [
        Text(
          'What kind of post do you want to do?',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xff787878), fontSize: 17),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            renderType(context, CommentType.COMMENT),
            renderType(context, CommentType.TIPS),
            renderType(context, CommentType.DIAGNOSIS),
            renderType(context, CommentType.RECOMMEND, onTap: () {
              BlocProvider.of<MainNavigatorBloc>(context).add(
                  MainNavigateToSelectNewProductEvent([],
                      futureFn: (future) async {
                List<Product> products = await future;
                if (products == null || products.length == 0) {
                  return;
                }
                setState(() {
                  this.recommended = products;
                  this.type = CommentType.RECOMMEND;
                  inputFocus.requestFocus();
                  this.replyTo = null;
                  this.replyToDisplay = null;
                });
              }));
            }),
          ],
        ),
      ]);
    } else {
      Map<String, String> commentType = commentTypes[type];
      Widget name = Text(
        commentType['prompt'],
        style: TextStyle(
          color: Color(0xff474747),
          fontSize: 16,
        ),
      );
      if (type == CommentType.RECOMMEND && recommended.length > 0) {
        name = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            name,
            Row(children: [
              Text(recommended[0].name,
                  style: TextStyle(fontWeight: FontWeight.bold)),
              recommended[0].supplier != null
                  ? Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          recommended[0].supplier.url,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                        ),
                      ),
                    )
                  : Container(),
              recommended.length > 1
                  ? Text(
                      '(+${recommended.length - 1} other)',
                      style: TextStyle(color: Color(0xff919191)),
                    )
                  : Container(),
            ]),
          ],
        );
      }

      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Padding(
            padding: const EdgeInsets.only(right: 24, top: 8.0, bottom: 8.0),
            child: Image.asset(commentType['pic'], width: 25, height: 25),
          ),
          Expanded(child: name),
          IconButton(
            onPressed: () {
              setState(() {
                type = CommentType.COMMENT;
                FocusScope.of(context).unfocus();
                this.replyTo = null;
                this.replyToDisplay = null;
              });
            },
            icon: Icon(Icons.close),
          ),
        ]),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        height: 1,
        color: Color(0xffcdcdcd),
        margin: EdgeInsets.only(bottom: 6.0),
      ),
      AnimatedSizeAndFade(
          vsync: this,
          fadeDuration: Duration(milliseconds: 200),
          sizeDuration: Duration(milliseconds: 200),
          child: content),
      renderInput(context),
    ]);
  }

  Widget renderInput(BuildContext context) {
    String pic = user.pic;
    if (pic != null) {
      pic = BackendAPI().feedsAPI.absoluteFileURL(pic);
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          UserAvatar(
            icon: pic,
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  border: Border.all(width: 1, color: Colors.black26),
                  borderRadius: BorderRadius.circular(25.0)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 0),
                      child: TextField(
                        autofocus: autoFocus,
                        focusNode: inputFocus,
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Add a comment as stant...'),
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(fontSize: 17),
                        minLines: 1,
                        maxLines: 4,
                        controller: textEditingController,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      BlocProvider.of<CommentsFormBloc>(context).add(
                          CommentsFormBlocEventPostComment(
                              textEditingController.text,
                              type,
                              replyTo,
                              recommended));
                      FocusScope.of(context).unfocus();
                      textEditingController.clear();
                      type = CommentType.COMMENT;
                      this.replyTo = null;
                      this.replyToDisplay = null;
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Text('Post',
                          style: TextStyle(
                              color: Color(0xff001AFF),
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget renderType(BuildContext context, CommentType type, {Function onTap}) {
    Map<String, String> commentType = commentTypes[type];
    return InkWell(
        onTap: onTap ??
            () {
              setState(() {
                if (type == CommentType.COMMENT) {
                  return;
                }
                this.type = type;
                inputFocus.requestFocus();
                this.recommended = null;
                this.replyTo = null;
                this.replyToDisplay = null;
              });
            },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                commentType['name'],
                style: TextStyle(
                    color: Color(0xff474747),
                    fontSize: 16,
                    fontWeight: this.type == type
                        ? FontWeight.bold
                        : FontWeight.normal),
              ),
              Container(
                margin: const EdgeInsets.all(5.0),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                    border: Border.all(
                        width: this.type == type ? 2 : 1,
                        color: this.type == type
                            ? Color(0xff3bb30b)
                            : Color(0xffbdbdbd)),
                    borderRadius: BorderRadius.all(Radius.circular(25))),
                child: Image.asset(commentType['pic'], width: 25, height: 25),
              ),
            ],
          ),
        ));
  }

  void insertNewComment(Comment comment) {
    int index;
    if (comment.replyTo != null) {
      int startIndex = comments.lastIndexWhere(
              (c) => c.id == comment.replyTo || c.replyTo == comment.replyTo) +
          1;
      index = comments.lastIndexWhere(
          (c) =>
              c.replyTo == comment.replyTo &&
              c.createdAt.isAfter(comment.createdAt),
          startIndex);
      index = index < 0 ? startIndex : index;
    } else {
      index = comments.indexWhere(
          (c) => c.replyTo == null && c.createdAt.isBefore(comment.createdAt));
      index = index < 0 ? comments.length : index;
    }
    if (listKey.currentState != null) {
      listKey.currentState
          .insertItem(index, duration: Duration(milliseconds: 200));
    }
    comments.insert(index, comment);
  }

  @override
  void dispose() {
    inputFocus.dispose();
    super.dispose();
  }
}
