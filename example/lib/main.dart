import 'package:better_flutter/frame/frame.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(builder: (context) {
        return Scaffold(
          body: Center(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                border: Border.all(color: Colors.white.withOpacity(0.8)),
                image: const DecorationImage(
                  image: NetworkImage('https://picsum.photos/250?image=9'),
                  opacity: 0.7,
                ),
              ),
              child: Frame(
                style: Style(
                  backgroundColor: Colors.orange.withOpacity(0.8),
                  // backgroundGradient: ,
                  backdropBlur: 4,
                  borderRadius: BorderRadius.circular(50),
                  dropShadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.25),
                      offset: const Offset(0, 3),
                      blurRadius: 20,
                    ),
                  ],
                  innerShadows: [
                    Shadow(
                      color: Colors.red.withOpacity(1),
                      offset: const Offset(-3, -3),
                      blurRadius: 5,
                    ),
                    Shadow(
                      color: Colors.yellow.withOpacity(1),
                      offset: const Offset(3, 3),
                      blurRadius: 5,
                    ),
                  ],
                ),
                box: BoxModel(
                  margin: const EdgeInsets.all(12),
                  height: 200,
                  width: 200,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
