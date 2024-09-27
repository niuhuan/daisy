import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'images.dart';

const double _avatarMargin = 5;
const double _avatarBorderSize = 1.5;

// 头像
class Avatar extends StatelessWidget {
  final String url;
  final int uid;
  final double size;

  const Avatar(
    this.url,
    this.uid, {
    this.size = 50,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(_avatarMargin),
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.secondary,
            style: BorderStyle.solid,
            width: _avatarBorderSize,
          )),
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(size)),
        child: url == "null" ? SvgPicture.asset(
          'lib/assets/unknown.svg',
          width: size,
          height: size,
          color: Colors.grey.shade600,
        ) :LoadingCacheImage(
          width: size,
          height: size,
          fit: BoxFit.cover,
          url: url,
          useful: 'avatar',
          extendsFieldIntFirst: uid,
        ),
      ),
    );
  }
}
