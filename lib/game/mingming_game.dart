import 'dart:async' as async_timer;
import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart';
import 'package:mingming/utils/constants.dart';

enum CatMood {
  sad,
  eating,
  happy,
}

class MingmingGame extends FlameGame {
  SpriteAnimationComponent? _catSprite;
  CatMood _currentMood = CatMood.sad;
  String? _currentAnimation;
  final Random _random = Random();
  async_timer.Timer? _animationChangeTimer;
  async_timer.Timer? _hungerTimer;

  // Animation data - all set to loop
  final Map<String, SpriteAnimationData> _animationData = {
    'cat_eat': SpriteAnimationData.sequenced(
      amount: 15,
      stepTime: 0.1,
      textureSize: Vector2(32, 32),
      loop: true,
    ),
    'cat_cry': SpriteAnimationData.sequenced(
      amount: 4,
      stepTime: 0.15,
      textureSize: Vector2(32, 32),
      loop: true,
    ),
    'cat_idle': SpriteAnimationData.sequenced(
      amount: 10,
      stepTime: 0.1,
      textureSize: Vector2(32, 32),
      loop: true,
    ),
    'cat_laydown': SpriteAnimationData.sequenced(
      amount: 12,
      stepTime: 0.12,
      textureSize: Vector2(32, 32),
      loop: true,
    ),
    'cat_sad': SpriteAnimationData.sequenced(
      amount: 9,
      stepTime: 0.11,
      textureSize: Vector2(32, 32),
      loop: true,
    ),
    'cat_dance': SpriteAnimationData.sequenced(
      amount: 4,
      stepTime: 0.15,
      textureSize: Vector2(32, 32),
      loop: true,
    ),
    'cat_sleep': SpriteAnimationData.sequenced(
      amount: 4,
      stepTime: 0.2,
      textureSize: Vector2(32, 32),
      loop: true,
    ),
    'cat_excited': SpriteAnimationData.sequenced(
      amount: 12,
      stepTime: 0.1,
      textureSize: Vector2(32, 32),
      loop: true,
    ),
  };

  final List<String> _sadAnimations = [
    'cat_cry',
    'cat_idle',
    'cat_laydown',
    'cat_sad',
  ];

  final List<String> _happyAnimations = [
    'cat_dance',
    'cat_sleep',
    'cat_excited',
  ];

  @override
  Color backgroundColor() => kPrimary;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _playRandomSadAnimation();
  }

  @override
  void onRemove() {
    _animationChangeTimer?.cancel();
    _hungerTimer?.cancel();
    super.onRemove();
  }

  Future<void> _playRandomSadAnimation() async {
    final randomAnimation = _sadAnimations[_random.nextInt(_sadAnimations.length)];
    await _playAnimation(randomAnimation);

    // Schedule next animation change in 1 minute
    _animationChangeTimer?.cancel();
    _animationChangeTimer = async_timer.Timer(Duration(minutes: 1), () {
      if (_currentMood == CatMood.sad) {
        _playRandomSadAnimation();
      }
    });
  }

  Future<void> _playRandomHappyAnimation() async {
    final randomAnimation = _happyAnimations[_random.nextInt(_happyAnimations.length)];
    await _playAnimation(randomAnimation);

    // Schedule next animation change in 1 minute
    _animationChangeTimer?.cancel();
    _animationChangeTimer = async_timer.Timer(Duration(minutes: 1), () {
      if (_currentMood == CatMood.happy) {
        _playRandomHappyAnimation();
      }
    });
  }

  Future<void> _playAnimation(String animationName) async {
    _currentAnimation = animationName;

    if (_catSprite != null) {
      remove(_catSprite!);
    }

    final image = await images.load('sprites/$animationName.png');
    final animation = SpriteAnimation.fromFrameData(
      image,
      _animationData[animationName]!,
    );

    _catSprite = SpriteAnimationComponent(
      animation: animation,
      size: Vector2(128, 128),
    )
      ..anchor = Anchor.center
      ..position = size / 2;

    add(_catSprite!);
  }

  Future<void> feed({Duration? hungerDuration}) async {
    if (_currentMood == CatMood.eating || _currentMood == CatMood.happy) {
      return; // Already fed
    }

    // Cancel existing timers
    _animationChangeTimer?.cancel();
    _hungerTimer?.cancel();

    // Switch to eating
    _currentMood = CatMood.eating;
    await _playAnimation('cat_eat');

    // After 1 minute of eating, switch to happy
    async_timer.Timer(Duration(minutes: 1), () async {
      _currentMood = CatMood.happy;
      await _playRandomHappyAnimation();

      // Use provided hunger duration or default to cooldown duration
      final actualHungerDuration = hungerDuration ?? Duration(hours: 2);

      // After hunger duration, switch back to sad
      _hungerTimer = async_timer.Timer(actualHungerDuration, () async {
        _currentMood = CatMood.sad;
        await _playRandomSadAnimation();
      });
    });
  }

  void makeHungry() async {
    _hungerTimer?.cancel();
    _animationChangeTimer?.cancel();

    if (_currentMood != CatMood.sad) {
      _currentMood = CatMood.sad;
      await _playRandomSadAnimation();
    }
  }

  CatMood get currentMood => _currentMood;

  bool get isHungry => _currentMood == CatMood.sad;
  bool get isHappy => _currentMood == CatMood.happy;
  bool get isEating => _currentMood == CatMood.eating;
}