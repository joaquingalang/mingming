import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart';
import 'package:mingming/utils/constants.dart';

class MingmingGame extends FlameGame {

  @override
  Color backgroundColor() => kPrimary;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final image = await images.load('sprites/cat_idle.png');

    final animation = SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: 8,
        stepTime: 0.1,
        textureSize: Vector2(32, 32),
      ),
    );

    final sprite = SpriteAnimationComponent(
      animation: animation,
      size: Vector2(128, 128),
    )
      ..anchor = Anchor.center
      ..position = size / 2;

    add(sprite);
  }

}
