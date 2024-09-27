import 'dart:convert';

import 'package:daisy/src/rust/anime_home/entities.dart';

const double coverWidth = 270;
const double coverHeight = 360;

class ComicCategoryGroup<T> {
  T matter;
  T userGroup;
  T processStatus;
  T region;

  ComicCategoryGroup(
    this.matter,
    this.userGroup,
    this.processStatus,
    this.region,
  );

  List<T> filtered() {
    List<T> list = [];
    if (matter != null) {
      list.add(matter);
    }
    if (userGroup != null) {
      list.add(userGroup);
    }
    if (processStatus != null) {
      list.add(processStatus);
    }
    if (region != null) {
      list.add(region);
    }
    return list;
  }
}

final comicCategories = ComicCategoryGroup<List<ComicCategory>>(
  [
    const ComicCategory(
      tagId: 4,
      title: "冒险",
      cover: "https://images.dmzj.com/tuijian/222_222/180720maoxian.jpg",
    ),
    const ComicCategory(
      tagId: 7900,
      title: "仙侠",
      cover: "https://images.dmzj.com/tuijian/222_222/170811xianxia.jpg",
    ),
    const ComicCategory(
      tagId: 3244,
      title: "秀吉",
      cover: "https://images.dmzj.com/tuijian/222_222/180803weiniang.jpg",
    ),
    const ComicCategory(
      tagId: 13,
      title: "校园",
      cover: "https://images.dmzj.com/tuijian/222_222/170811xiaoyuan.jpg",
    ),
    const ComicCategory(
      tagId: 6,
      title: "格斗",
      cover: "https://images.dmzj.com/tuijian/222_222/170811gedou.jpg",
    ),
    const ComicCategory(
      tagId: 8,
      title: "爱情",
      cover: "https://images.dmzj.com/tuijian/222_222/170811shenqi.jpg",
    ),
    const ComicCategory(
      tagId: 3245,
      title: "悬疑",
      cover: "https://images.dmzj.com/tuijian/222_222/kongbu.jpg",
    ),
    const ComicCategory(
      tagId: 3327,
      title: "美食",
      cover: "https://images.dmzj.com/tuijian/222_222/170811meishi.jpg",
    ),
    const ComicCategory(
      tagId: 6316,
      title: "轻小说改",
      cover: "https://images.dmzj.com/tuijian/222_222/170811qinggai.jpg",
    ),
    const ComicCategory(
      tagId: 4518,
      title: "TS",
      cover: "https://images.muwai.com/tuijian/222_222/170817xingzhuan.jpg",
    ),
    const ComicCategory(
      tagId: 5806,
      title: "魔幻",
      cover: "https://images.dmzj.com/tuijian/222_222/170817mohuan.jpg",
    ),
    const ComicCategory(
      tagId: 3255,
      title: "励志",
      cover: "https://images.dmzj.com/tuijian/222_222/170817lizhi.jpg",
    ),
    const ComicCategory(
      tagId: 3254,
      title: "治愈",
      cover: "https://images.dmzj.com/tuijian/222_222/170817zhiyu.jpg",
    ),
    const ComicCategory(
      tagId: 3252,
      title: "萌系",
      cover: "https://images.dmzj.com/tuijian/222_222/170817mengxi.jpg",
    ),
    const ComicCategory(
      tagId: 3248,
      title: "热血",
      cover: "https://images.dmzj.com/tuijian/222_222/170817rexue.jpg",
    ),
    const ComicCategory(
      tagId: 17,
      title: "四格",
      cover: "https://images.dmzj.com/tuijian/222_222/170817sige.jpg",
    ),
    const ComicCategory(
      tagId: 12,
      title: "神鬼",
      cover: "https://images.dmzj.com/tuijian/222_222/170817shengui.jpg",
    ),
    const ComicCategory(
      tagId: 11,
      title: "魔法",
      cover: "https://images.dmzj.com/tuijian/222_222/170817mofa.jpg",
    ),
    const ComicCategory(
      tagId: 9,
      title: "侦探",
      cover: "https://images.dmzj.com/tuijian/222_222/170817zhentan.jpg",
    ),
    const ComicCategory(
      tagId: 7,
      title: "科幻",
      cover: "https://images.dmzj.com/tuijian/222_222/170817kehuan.jpg",
    ),
    const ComicCategory(
      tagId: 10,
      title: "竞技",
      cover: "https://images.dmzj.com/tuijian/222_222/170811jingji.jpg",
    ),
    const ComicCategory(
      tagId: 5848,
      title: "奇幻",
      cover: "https://images.dmzj.com/tuijian/222_222/170811qihuan.jpg",
    ),
    const ComicCategory(
      tagId: 6437,
      title: "颜艺",
      cover: "https://images.muwai.com/tuijian/222_222/170811yanyi.jpg",
    ),
    const ComicCategory(
      tagId: 7568,
      title: "搞笑",
      cover: "https://images.muwai.com/tuijian/222_222/170811gaoxiao.jpg",
    ),
    const ComicCategory(
      tagId: 3328,
      title: "职场",
      cover: "https://images.muwai.com/tuijian/222_222/170811zhichang.jpg",
    ),
    const ComicCategory(
      tagId: 5077,
      title: "东方",
      cover: "https://images.muwai.com/tuijian/222_222/170817dongfang.jpg",
    ),
    const ComicCategory(
      tagId: 13627,
      title: "舰娘",
      cover: "https://images.muwai.com/tuijian/222_222/170817jianniang.jpg",
    ),
  ],
  [
    const ComicCategory(
      tagId: 3262,
      title: "少年漫",
      cover: "https://images.dmzj.com/tuijian/222_222/180720shaonianman.jpg",
    ),
    const ComicCategory(
      tagId: 3263,
      title: "少女漫",
      cover: "https://images.dmzj.com/tuijian/222_222/180720shaonvman.jpg",
    ),
    const ComicCategory(
      tagId: 13626,
      title: "女青漫",
      cover: "https://images.dmzj.com/tuijian/222_222/180720nvqingman.jpg",
    ),
    const ComicCategory(
      tagId: 3264,
      title: "青年漫",
      cover: "https://images.dmzj.com/tuijian/222_222/180720qingnianman.jpg",
    ),
  ],
  [
    const ComicCategory(
      tagId: 2309,
      title: "连载",
      cover: "https://images.dmzj.com/tuijian/222_222/180720lianzai.jpg",
    ),
    const ComicCategory(
      tagId: 2310,
      title: "完结",
      cover: "https://images.dmzj.com/tuijian/222_222/180720wanjie.jpg",
    ),
  ],
  [
    const ComicCategory(
      tagId: 2308,
      title: "国漫",
      cover: "https://images.dmzj.com/tuijian/222_222/180720guoman.jpg",
    ),
    const ComicCategory(
      tagId: 2305,
      title: "韩国",
      cover: "https://images.dmzj.com/tuijian/222_222/180720hanguo.jpg",
    ),
    const ComicCategory(
      tagId: 2306,
      title: "欧美",
      cover: "https://images.dmzj.com/tuijian/222_222/180720oumei.jpg",
    ),
    const ComicCategory(
      tagId: 2304,
      title: "日本",
      cover: "https://images.dmzj.com/tuijian/222_222/180720riben.jpg",
    ),
  ],
);

class NovelCategoryDart {
  NovelCategoryDart({
    required this.tagId,
    required this.title,
    required this.cover,
  });

  late final int tagId;
  late final String title;
  late final String cover;

  NovelCategoryDart.fromJson(Map<String, dynamic> json) {
    tagId = json['tag_id'];
    title = json['title'];
    cover = json['cover'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['tag_id'] = tagId;
    data['title'] = title;
    data['cover'] = cover;
    return data;
  }
}

const _novelCategoriesJson =
    '[{"tag_id":20,"title":"\u5192\u9669","cover":"https://images.dmzj.com/tuijian/xiaoshuo/fenlei/maoxian.jpg"},{"tag_id":40,"title":"\u641e\u7b11","cover":"https://images.dmzj.com/tuijian/xiaoshuo/fenlei/gaoxiao.jpg"},{"tag_id":47,"title":"\u6218\u6597","cover":"https://images.dmzj.com/tuijian/xiaoshuo/fenlei/zhandou.jpg"},{"tag_id":4,"title":"\u79d1\u5e7b","cover":"https://images.dmzj.com/tuijian/xiaoshuo/fenlei/kehuan.jpg"},{"tag_id":8,"title":"\u604b\u7231","cover":"https://images.dmzj.com/tuijian/xiaoshuo/fenlei/aiqing.jpg"},{"tag_id":6,"title":"\u4fa6\u63a2","cover":"https://images.dmzj.com/tuijian/xiaoshuo/fenlei/zhentan.jpg"},{"tag_id":16,"title":"\u9b54\u6cd5","cover":"https://images.dmzj.com/tuijian/xiaoshuo/fenlei/mofa.jpg"},{"tag_id":14,"title":"\u795e\u9b3c","cover":"https://images.dmzj.com/tuijian/xiaoshuo/fenlei/shengui.jpg"},{"tag_id":12,"title":"\u6821\u56ed","cover":"https://images.dmzj.com/tuijian/xiaoshuo/fenlei/xiaoyuan.jpg"},{"tag_id":2,"title":"\u6050\u6016","cover":"https://images.dmzj.com/tuijian/xiaoshuo/fenlei/kongbu.jpg"},{"tag_id":25,"title":"\u5176\u4ed6","cover":"https://images.dmzj.com/tuijian/xiaoshuo/fenlei/qita.jpg"}]';
final List<NovelCategoryDart> novelCategories =
    List.of(jsonDecode(_novelCategoriesJson))
        .map((e) => NovelCategoryDart.fromJson(e))
        .toList()
        .cast();
