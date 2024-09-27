import 'package:daisy/src/rust/api/bridge.dart' as native;
import 'package:daisy/screens/components/item_builder.dart';
import 'package:flutter/material.dart';

import '../../commons.dart';
import '../../src/rust/anime_home/entities.dart';
import 'avatar.dart';

class CommentPager extends StatefulWidget {
  final int objType;
  final int objId;
  final bool hot;

  const CommentPager(this.objType, this.objId, this.hot, {super.key});

  @override
  State<StatefulWidget> createState() => _CommentPagerState();
}

class _CommentPagerState extends State<CommentPager> {
  int _currentPage = 1;
  late Future<List<Comment>> _future;

  void _loadPage() {
    _future = native.comment(
        objType: widget.objType,
        objId: widget.objId,
        hot: widget.hot,
        page: _currentPage);
  }

  @override
  void initState() {
    _loadPage();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ItemBuilder(
      future: _future,
      onRefresh: () async {
        setState(() {
          _loadPage();
        });
      },
      successBuilder: (
        BuildContext context,
        AsyncSnapshot<List<Comment>> snapshot,
      ) {
        final list = snapshot.requireData;

        return Column(children: [
          _buildPrePage(),
          ...list.map((e) => _buildComment(e)),
          _buildNextPage(list),
          _buildPostComment(),
        ]);
      },
    );
  }

  Widget _buildComment(Comment comment) {
    return InkWell(
      onTap: () {
        // Navigator.of(context).push(
        //   MaterialPageRoute(
        //     builder: (context) =>
        //         CommentScreen(widget.mainType, widget.mainId, comment),
        //   ),
        // );
      },
      child: ComicCommentItem(comment),
    );
  }

  Widget _buildPrePage() {
    if (_currentPage > 1) {
      return InkWell(
        onTap: () {
          setState(() {
            _currentPage--;
            _loadPage();
          });
        },
        child: Container(
          padding: const EdgeInsets.all(30),
          child: const Center(
            child: Text('上一页'),
          ),
        ),
      );
    }
    return Container();
  }

  Widget _buildNextPage(List<Comment> list) {
    if (list.isNotEmpty) {
      return InkWell(
        onTap: () {
          setState(() {
            _currentPage++;
            _loadPage();
          });
        },
        child: Container(
          padding: const EdgeInsets.all(30),
          child: const Center(
            child: Text('下一页'),
          ),
        ),
      );
    }
    return Container();
  }



  Widget _buildPostComment() {
    return InkWell(
      onTap: () async {
        defaultToast(context, "未开发完成");
        // String? text = await inputString(context, '请输入评论内容');
        // if (text != null && text.isNotEmpty) {
        //   try {
        //     switch (widget.mainType) {
        //       case CommentMainType.COMIC:
        //         await method.postChildComment(widget.comment.id, text);
        //         break;
        //       case CommentMainType.GAME:
        //         await method.postGameChildComment(widget.comment.id, text);
        //         break;
        //     }
        //     setState(() {
        //       _future = _loadPage();
        //       widget.comment.commentsCount++;
        //     });
        //   } catch (e) {
        //     defaultToast(context, "评论失败");
        //   }
        // }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              width: .25,
              style: BorderStyle.solid,
              color: Colors.grey.shade500.withOpacity(.5),
            ),
            bottom: BorderSide(
              width: .25,
              style: BorderStyle.solid,
              color: Colors.grey.shade500.withOpacity(.5),
            ),
          ),
        ),
        padding: const EdgeInsets.all(30),
        child: const Center(
          child: Text('我有话要讲'),
        ),
      ),
    );
  }
}

class ComicCommentItem extends StatefulWidget {
  final Comment comment;

  const ComicCommentItem(this.comment, {super.key});

  @override
  State<StatefulWidget> createState() => _ComicCommentItemState();
}

class _ComicCommentItemState extends State<ComicCommentItem> {
  var likeLoading = false;

  @override
  Widget build(BuildContext context) {
    var comment = widget.comment;
    var theme = Theme.of(context);
    var nameStyle = const TextStyle(fontWeight: FontWeight.bold);
    var connectStyle =
        TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(.8));
    var datetimeStyle = TextStyle(
        color: theme.textTheme.bodyMedium?.color?.withOpacity(.6), fontSize: 12);
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            width: .25,
            style: BorderStyle.solid,
            color: Colors.grey.shade500.withOpacity(.5),
          ),
          bottom: BorderSide(
            width: .25,
            style: BorderStyle.solid,
            color: Colors.grey.shade500.withOpacity(.5),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Avatar(comment.avatarUrl,comment.senderUid),
          Container(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return SizedBox(
                      width: constraints.maxWidth,
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          Text(comment.nickname, style: nameStyle),
                          Text(
                            formatTimeToDateTime(comment.createTime),
                            style: datetimeStyle,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Container(height: 3),
                Container(height: 3),
                Text(comment.content, style: connectStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
