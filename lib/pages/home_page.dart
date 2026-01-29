import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:mingming/game/mingming_game.dart';
import 'package:mingming/utils/constants.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 128),
                    width: 128,
                    height: 128,
                    child: GameWidget(game: MingmingGame()),
                  ),
                  Text("I'M HUNGRY!", style: kPixelifyTitleMedium),
                ],
              ),
            ),
          ),

          GestureDetector(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                color: kSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text('FEED', style: kPixelifyHeadlineSmall)),
            ),
          ),
        ],
      ),
      backgroundColor: kPrimary,
    );
  }
}
