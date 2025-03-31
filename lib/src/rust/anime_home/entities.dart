// This file is automatically generated, so please do not edit it.
// @generated by `flutter_rust_bridge`@ 2.9.0.

// ignore_for_file: invalid_use_of_internal_member, unused_import, unnecessary_import

import '../frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

class ApiComment {
  final String id;
  final String objId;
  final String content;
  final String senderIp;
  final String senderUid;
  final String isGoods;
  final String uploadImages;
  final String createTime;
  final String likeAmount;
  final String senderTerminal;
  final String originCommentId;
  final String nickname;
  final String userLevel;
  final String mPeriod;
  final String mCate;
  final bool isFeeUser;
  final String avatarUrl;
  final String sex;
  final bool isLike;

  const ApiComment({
    required this.id,
    required this.objId,
    required this.content,
    required this.senderIp,
    required this.senderUid,
    required this.isGoods,
    required this.uploadImages,
    required this.createTime,
    required this.likeAmount,
    required this.senderTerminal,
    required this.originCommentId,
    required this.nickname,
    required this.userLevel,
    required this.mPeriod,
    required this.mCate,
    required this.isFeeUser,
    required this.avatarUrl,
    required this.sex,
    required this.isLike,
  });

  @override
  int get hashCode =>
      id.hashCode ^
      objId.hashCode ^
      content.hashCode ^
      senderIp.hashCode ^
      senderUid.hashCode ^
      isGoods.hashCode ^
      uploadImages.hashCode ^
      createTime.hashCode ^
      likeAmount.hashCode ^
      senderTerminal.hashCode ^
      originCommentId.hashCode ^
      nickname.hashCode ^
      userLevel.hashCode ^
      mPeriod.hashCode ^
      mCate.hashCode ^
      isFeeUser.hashCode ^
      avatarUrl.hashCode ^
      sex.hashCode ^
      isLike.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiComment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          objId == other.objId &&
          content == other.content &&
          senderIp == other.senderIp &&
          senderUid == other.senderUid &&
          isGoods == other.isGoods &&
          uploadImages == other.uploadImages &&
          createTime == other.createTime &&
          likeAmount == other.likeAmount &&
          senderTerminal == other.senderTerminal &&
          originCommentId == other.originCommentId &&
          nickname == other.nickname &&
          userLevel == other.userLevel &&
          mPeriod == other.mPeriod &&
          mCate == other.mCate &&
          isFeeUser == other.isFeeUser &&
          avatarUrl == other.avatarUrl &&
          sex == other.sex &&
          isLike == other.isLike;
}

class ApiCommentResponse {
  final List<String> commentIds;
  final Map<String, ApiComment> comments;
  final PlatformInt64 total;

  const ApiCommentResponse({
    required this.commentIds,
    required this.comments,
    required this.total,
  });

  @override
  int get hashCode => commentIds.hashCode ^ comments.hashCode ^ total.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiCommentResponse &&
          runtimeType == other.runtimeType &&
          commentIds == other.commentIds &&
          comments == other.comments &&
          total == other.total;
}

class Author {
  final String nickname;
  final String description;
  final String cover;
  final List<ComicInAuthor> data;

  const Author({
    required this.nickname,
    required this.description,
    required this.cover,
    required this.data,
  });

  @override
  int get hashCode =>
      nickname.hashCode ^ description.hashCode ^ cover.hashCode ^ data.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Author &&
          runtimeType == other.runtimeType &&
          nickname == other.nickname &&
          description == other.description &&
          cover == other.cover &&
          data == other.data;
}

class ComicCategory {
  final int tagId;
  final String title;
  final String cover;

  const ComicCategory({
    required this.tagId,
    required this.title,
    required this.cover,
  });

  @override
  int get hashCode => tagId.hashCode ^ title.hashCode ^ cover.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComicCategory &&
          runtimeType == other.runtimeType &&
          tagId == other.tagId &&
          title == other.title &&
          cover == other.cover;
}

class ComicFilter {
  final String title;
  final List<ComicFilterItem> items;

  const ComicFilter({
    required this.title,
    required this.items,
  });

  @override
  int get hashCode => title.hashCode ^ items.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComicFilter &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          items == other.items;
}

class ComicFilterItem {
  final PlatformInt64 tagId;
  final String tagName;

  const ComicFilterItem({
    required this.tagId,
    required this.tagName,
  });

  @override
  int get hashCode => tagId.hashCode ^ tagName.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComicFilterItem &&
          runtimeType == other.runtimeType &&
          tagId == other.tagId &&
          tagName == other.tagName;
}

class ComicInAuthor {
  final PlatformInt64 id;
  final String name;
  final String cover;
  final String status;

  const ComicInAuthor({
    required this.id,
    required this.name,
    required this.cover,
    required this.status,
  });

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ cover.hashCode ^ status.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComicInAuthor &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          cover == other.cover &&
          status == other.status;
}

class ComicInFilter {
  final PlatformInt64 id;
  final String title;
  final String authors;
  final String status;
  final String cover;
  final String types;
  final PlatformInt64 lastUpdateTime;
  final PlatformInt64 num;

  const ComicInFilter({
    required this.id,
    required this.title,
    required this.authors,
    required this.status,
    required this.cover,
    required this.types,
    required this.lastUpdateTime,
    required this.num,
  });

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      authors.hashCode ^
      status.hashCode ^
      cover.hashCode ^
      types.hashCode ^
      lastUpdateTime.hashCode ^
      num.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComicInFilter &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          authors == other.authors &&
          status == other.status &&
          cover == other.cover &&
          types == other.types &&
          lastUpdateTime == other.lastUpdateTime &&
          num == other.num;
}

class ComicInSearch {
  final String biz;
  final PlatformInt64 addtime;
  final String authors;
  final PlatformInt64 copyright;
  final String cover;
  final PlatformInt64 hidden;
  final PlatformInt64 hotHits;
  final String lastName;
  final PlatformInt64 status;
  final String title;
  final String types;
  final PlatformInt64 id;

  const ComicInSearch({
    required this.biz,
    required this.addtime,
    required this.authors,
    required this.copyright,
    required this.cover,
    required this.hidden,
    required this.hotHits,
    required this.lastName,
    required this.status,
    required this.title,
    required this.types,
    required this.id,
  });

  @override
  int get hashCode =>
      biz.hashCode ^
      addtime.hashCode ^
      authors.hashCode ^
      copyright.hashCode ^
      cover.hashCode ^
      hidden.hashCode ^
      hotHits.hashCode ^
      lastName.hashCode ^
      status.hashCode ^
      title.hashCode ^
      types.hashCode ^
      id.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComicInSearch &&
          runtimeType == other.runtimeType &&
          biz == other.biz &&
          addtime == other.addtime &&
          authors == other.authors &&
          copyright == other.copyright &&
          cover == other.cover &&
          hidden == other.hidden &&
          hotHits == other.hotHits &&
          lastName == other.lastName &&
          status == other.status &&
          title == other.title &&
          types == other.types &&
          id == other.id;
}

class Comment {
  final PlatformInt64 id;
  final PlatformInt64 isPassed;
  final PlatformInt64 topStatus;
  final PlatformInt64 isGoods;
  final String uploadImages;
  final PlatformInt64 objId;
  final String content;
  final PlatformInt64 senderUid;
  final PlatformInt64 likeAmount;
  final PlatformInt64 createTime;
  final PlatformInt64 toUid;
  final PlatformInt64 toCommentId;
  final PlatformInt64 originCommentId;
  final PlatformInt64 replyAmount;
  final PlatformInt64 hotCommentAmount;
  final String cover;
  final String nickname;
  final String avatarUrl;
  final PlatformInt64 sex;
  final PlatformInt64 masterCommentNum;
  final List<MasterComment> masterComment;

  const Comment({
    required this.id,
    required this.isPassed,
    required this.topStatus,
    required this.isGoods,
    required this.uploadImages,
    required this.objId,
    required this.content,
    required this.senderUid,
    required this.likeAmount,
    required this.createTime,
    required this.toUid,
    required this.toCommentId,
    required this.originCommentId,
    required this.replyAmount,
    required this.hotCommentAmount,
    required this.cover,
    required this.nickname,
    required this.avatarUrl,
    required this.sex,
    required this.masterCommentNum,
    required this.masterComment,
  });

  @override
  int get hashCode =>
      id.hashCode ^
      isPassed.hashCode ^
      topStatus.hashCode ^
      isGoods.hashCode ^
      uploadImages.hashCode ^
      objId.hashCode ^
      content.hashCode ^
      senderUid.hashCode ^
      likeAmount.hashCode ^
      createTime.hashCode ^
      toUid.hashCode ^
      toCommentId.hashCode ^
      originCommentId.hashCode ^
      replyAmount.hashCode ^
      hotCommentAmount.hashCode ^
      cover.hashCode ^
      nickname.hashCode ^
      avatarUrl.hashCode ^
      sex.hashCode ^
      masterCommentNum.hashCode ^
      masterComment.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Comment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          isPassed == other.isPassed &&
          topStatus == other.topStatus &&
          isGoods == other.isGoods &&
          uploadImages == other.uploadImages &&
          objId == other.objId &&
          content == other.content &&
          senderUid == other.senderUid &&
          likeAmount == other.likeAmount &&
          createTime == other.createTime &&
          toUid == other.toUid &&
          toCommentId == other.toCommentId &&
          originCommentId == other.originCommentId &&
          replyAmount == other.replyAmount &&
          hotCommentAmount == other.hotCommentAmount &&
          cover == other.cover &&
          nickname == other.nickname &&
          avatarUrl == other.avatarUrl &&
          sex == other.sex &&
          masterCommentNum == other.masterCommentNum &&
          masterComment == other.masterComment;
}

class DayList {
  final PlatformInt64 id;
  final String title;
  final String icon;
  final String iconChecked;
  final PlatformInt64 typeId;
  final PlatformInt64 times;
  final PlatformInt64 nums;
  final PlatformInt64 creditsNums;

  const DayList({
    required this.id,
    required this.title,
    required this.icon,
    required this.iconChecked,
    required this.typeId,
    required this.times,
    required this.nums,
    required this.creditsNums,
  });

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      icon.hashCode ^
      iconChecked.hashCode ^
      typeId.hashCode ^
      times.hashCode ^
      nums.hashCode ^
      creditsNums.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayList &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          icon == other.icon &&
          iconChecked == other.iconChecked &&
          typeId == other.typeId &&
          times == other.times &&
          nums == other.nums &&
          creditsNums == other.creditsNums;
}

class DaySignTask {
  final PlatformInt64 currentDay;
  final PlatformInt64 status;
  final PlatformInt64 doubleStatus;
  final List<DayList> dayList;

  const DaySignTask({
    required this.currentDay,
    required this.status,
    required this.doubleStatus,
    required this.dayList,
  });

  @override
  int get hashCode =>
      currentDay.hashCode ^
      status.hashCode ^
      doubleStatus.hashCode ^
      dayList.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DaySignTask &&
          runtimeType == other.runtimeType &&
          currentDay == other.currentDay &&
          status == other.status &&
          doubleStatus == other.doubleStatus &&
          dayList == other.dayList;
}

class LoginData {
  final String uid;
  final String nickname;
  final String dmzjToken;
  final String photo;
  final String bindPhone;
  final String email;
  final String passwd;

  const LoginData({
    required this.uid,
    required this.nickname,
    required this.dmzjToken,
    required this.photo,
    required this.bindPhone,
    required this.email,
    required this.passwd,
  });

  @override
  int get hashCode =>
      uid.hashCode ^
      nickname.hashCode ^
      dmzjToken.hashCode ^
      photo.hashCode ^
      bindPhone.hashCode ^
      email.hashCode ^
      passwd.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoginData &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          nickname == other.nickname &&
          dmzjToken == other.dmzjToken &&
          photo == other.photo &&
          bindPhone == other.bindPhone &&
          email == other.email &&
          passwd == other.passwd;
}

class MasterComment {
  final PlatformInt64 id;
  final PlatformInt64 isPassed;
  final PlatformInt64 topStatus;
  final PlatformInt64 isGoods;
  final String uploadImages;
  final PlatformInt64 objId;
  final String content;
  final PlatformInt64 senderUid;
  final PlatformInt64 likeAmount;
  final PlatformInt64 createTime;
  final PlatformInt64 toUid;
  final PlatformInt64 toCommentId;
  final PlatformInt64 originCommentId;
  final PlatformInt64 replyAmount;
  final String cover;
  final String nickname;
  final PlatformInt64 hotCommentAmount;
  final PlatformInt64 sex;

  const MasterComment({
    required this.id,
    required this.isPassed,
    required this.topStatus,
    required this.isGoods,
    required this.uploadImages,
    required this.objId,
    required this.content,
    required this.senderUid,
    required this.likeAmount,
    required this.createTime,
    required this.toUid,
    required this.toCommentId,
    required this.originCommentId,
    required this.replyAmount,
    required this.cover,
    required this.nickname,
    required this.hotCommentAmount,
    required this.sex,
  });

  @override
  int get hashCode =>
      id.hashCode ^
      isPassed.hashCode ^
      topStatus.hashCode ^
      isGoods.hashCode ^
      uploadImages.hashCode ^
      objId.hashCode ^
      content.hashCode ^
      senderUid.hashCode ^
      likeAmount.hashCode ^
      createTime.hashCode ^
      toUid.hashCode ^
      toCommentId.hashCode ^
      originCommentId.hashCode ^
      replyAmount.hashCode ^
      cover.hashCode ^
      nickname.hashCode ^
      hotCommentAmount.hashCode ^
      sex.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MasterComment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          isPassed == other.isPassed &&
          topStatus == other.topStatus &&
          isGoods == other.isGoods &&
          uploadImages == other.uploadImages &&
          objId == other.objId &&
          content == other.content &&
          senderUid == other.senderUid &&
          likeAmount == other.likeAmount &&
          createTime == other.createTime &&
          toUid == other.toUid &&
          toCommentId == other.toCommentId &&
          originCommentId == other.originCommentId &&
          replyAmount == other.replyAmount &&
          cover == other.cover &&
          nickname == other.nickname &&
          hotCommentAmount == other.hotCommentAmount &&
          sex == other.sex;
}

class NewsCategory {
  final PlatformInt64 tagId;
  final String tagName;

  const NewsCategory({
    required this.tagId,
    required this.tagName,
  });

  @override
  int get hashCode => tagId.hashCode ^ tagName.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NewsCategory &&
          runtimeType == other.runtimeType &&
          tagId == other.tagId &&
          tagName == other.tagName;
}

class NovelCategory {
  final PlatformInt64 tagId;
  final String title;
  final String cover;

  const NovelCategory({
    required this.tagId,
    required this.title,
    required this.cover,
  });

  @override
  int get hashCode => tagId.hashCode ^ title.hashCode ^ cover.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NovelCategory &&
          runtimeType == other.runtimeType &&
          tagId == other.tagId &&
          title == other.title &&
          cover == other.cover;
}

class NovelInFilter {
  final String cover;
  final String name;
  final String authors;
  final PlatformInt64 id;

  const NovelInFilter({
    required this.cover,
    required this.name,
    required this.authors,
    required this.id,
  });

  @override
  int get hashCode =>
      cover.hashCode ^ name.hashCode ^ authors.hashCode ^ id.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NovelInFilter &&
          runtimeType == other.runtimeType &&
          cover == other.cover &&
          name == other.name &&
          authors == other.authors &&
          id == other.id;
}

class NovelInSearch {
  final String biz;
  final PlatformInt64 addtime;
  final String authors;
  final PlatformInt64 copyright;
  final String cover;
  final PlatformInt64 hidden;
  final PlatformInt64 hotHits;
  final String lastName;
  final PlatformInt64 status;
  final String title;
  final String types;
  final PlatformInt64 id;

  const NovelInSearch({
    required this.biz,
    required this.addtime,
    required this.authors,
    required this.copyright,
    required this.cover,
    required this.hidden,
    required this.hotHits,
    required this.lastName,
    required this.status,
    required this.title,
    required this.types,
    required this.id,
  });

  @override
  int get hashCode =>
      biz.hashCode ^
      addtime.hashCode ^
      authors.hashCode ^
      copyright.hashCode ^
      cover.hashCode ^
      hidden.hashCode ^
      hotHits.hashCode ^
      lastName.hashCode ^
      status.hashCode ^
      title.hashCode ^
      types.hashCode ^
      id.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NovelInSearch &&
          runtimeType == other.runtimeType &&
          biz == other.biz &&
          addtime == other.addtime &&
          authors == other.authors &&
          copyright == other.copyright &&
          cover == other.cover &&
          hidden == other.hidden &&
          hotHits == other.hotHits &&
          lastName == other.lastName &&
          status == other.status &&
          title == other.title &&
          types == other.types &&
          id == other.id;
}

class Subscribed {
  final String name;
  final String subUpdate;
  final String subImg;
  final PlatformInt64 subUptime;
  final String subFirstLetter;
  final PlatformInt64 subReaded;
  final PlatformInt64 id;
  final String status;

  const Subscribed({
    required this.name,
    required this.subUpdate,
    required this.subImg,
    required this.subUptime,
    required this.subFirstLetter,
    required this.subReaded,
    required this.id,
    required this.status,
  });

  @override
  int get hashCode =>
      name.hashCode ^
      subUpdate.hashCode ^
      subImg.hashCode ^
      subUptime.hashCode ^
      subFirstLetter.hashCode ^
      subReaded.hashCode ^
      id.hashCode ^
      status.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Subscribed &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          subUpdate == other.subUpdate &&
          subImg == other.subImg &&
          subUptime == other.subUptime &&
          subFirstLetter == other.subFirstLetter &&
          subReaded == other.subReaded &&
          id == other.id &&
          status == other.status;
}

class SummationsTask {
  final PlatformInt64 signCount;
  final PlatformInt64 maxSignCount;
  final List<TaskList> taskList;

  const SummationsTask({
    required this.signCount,
    required this.maxSignCount,
    required this.taskList,
  });

  @override
  int get hashCode =>
      signCount.hashCode ^ maxSignCount.hashCode ^ taskList.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SummationsTask &&
          runtimeType == other.runtimeType &&
          signCount == other.signCount &&
          maxSignCount == other.maxSignCount &&
          taskList == other.taskList;
}

class Task {
  final PlatformInt64 id;
  final String title;
  final String con;
  final String icon;
  final PlatformInt64 times;
  final PlatformInt64 nums;
  final PlatformInt64 source;
  final PlatformInt64 typeId;
  final String url;
  final String btn;
  final PlatformInt64 status;
  final PlatformInt64 progress;

  const Task({
    required this.id,
    required this.title,
    required this.con,
    required this.icon,
    required this.times,
    required this.nums,
    required this.source,
    required this.typeId,
    required this.url,
    required this.btn,
    required this.status,
    required this.progress,
  });

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      con.hashCode ^
      icon.hashCode ^
      times.hashCode ^
      nums.hashCode ^
      source.hashCode ^
      typeId.hashCode ^
      url.hashCode ^
      btn.hashCode ^
      status.hashCode ^
      progress.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          con == other.con &&
          icon == other.icon &&
          times == other.times &&
          nums == other.nums &&
          source == other.source &&
          typeId == other.typeId &&
          url == other.url &&
          btn == other.btn &&
          status == other.status &&
          progress == other.progress;
}

class TaskIndex {
  final List<Task> newPersonTask;
  final List<Task> dayTask;
  final List<Task> weekTask;
  final SummationsTask summationsTask;
  final DaySignTask daySignTask;
  final PlatformInt64 creditsNums;
  final PlatformInt64 silverNums;
  final PlatformInt64 starsNums;

  const TaskIndex({
    required this.newPersonTask,
    required this.dayTask,
    required this.weekTask,
    required this.summationsTask,
    required this.daySignTask,
    required this.creditsNums,
    required this.silverNums,
    required this.starsNums,
  });

  @override
  int get hashCode =>
      newPersonTask.hashCode ^
      dayTask.hashCode ^
      weekTask.hashCode ^
      summationsTask.hashCode ^
      daySignTask.hashCode ^
      creditsNums.hashCode ^
      silverNums.hashCode ^
      starsNums.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskIndex &&
          runtimeType == other.runtimeType &&
          newPersonTask == other.newPersonTask &&
          dayTask == other.dayTask &&
          weekTask == other.weekTask &&
          summationsTask == other.summationsTask &&
          daySignTask == other.daySignTask &&
          creditsNums == other.creditsNums &&
          silverNums == other.silverNums &&
          starsNums == other.starsNums;
}

class TaskList {
  final PlatformInt64 id;
  final String title;
  final String con;
  final String icon;
  final PlatformInt64 times;
  final PlatformInt64 nums;
  final PlatformInt64 source;
  final PlatformInt64 typeId;
  final String url;
  final String btn;
  final PlatformInt64 status;
  final PlatformInt64 progress;
  final String iconChecked;

  const TaskList({
    required this.id,
    required this.title,
    required this.con,
    required this.icon,
    required this.times,
    required this.nums,
    required this.source,
    required this.typeId,
    required this.url,
    required this.btn,
    required this.status,
    required this.progress,
    required this.iconChecked,
  });

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      con.hashCode ^
      icon.hashCode ^
      times.hashCode ^
      nums.hashCode ^
      source.hashCode ^
      typeId.hashCode ^
      url.hashCode ^
      btn.hashCode ^
      status.hashCode ^
      progress.hashCode ^
      iconChecked.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskList &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          con == other.con &&
          icon == other.icon &&
          times == other.times &&
          nums == other.nums &&
          source == other.source &&
          typeId == other.typeId &&
          url == other.url &&
          btn == other.btn &&
          status == other.status &&
          progress == other.progress &&
          iconChecked == other.iconChecked;
}

class ViewPoint {
  final int id;
  final int uid;
  final String content;
  final PlatformInt64 num;
  final PlatformInt64 page;

  const ViewPoint({
    required this.id,
    required this.uid,
    required this.content,
    required this.num,
    required this.page,
  });

  @override
  int get hashCode =>
      id.hashCode ^
      uid.hashCode ^
      content.hashCode ^
      num.hashCode ^
      page.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ViewPoint &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          uid == other.uid &&
          content == other.content &&
          num == other.num &&
          page == other.page;
}
