import 'package:better_flutter/better_text.dart';
import 'package:flutter/material.dart';

class BetterTextView extends StatelessWidget {
  const BetterTextView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: BetterText(
        'Hello, {bold world!}\n{red heavy tap underline Click me!}\nI\'m a {cool bold cool text!}',
        colors: const {
          'cool': Colors.cyan,
        },
        actions: {
          'tap': () {
            showDialog(
              context: context,
              builder: (context) => const AlertDialog(
                title: Text('Hello, world!'),
              ),
            );
          }
        },
        textAlign: TextAlign.center,
        defaultStyle: const TextStyle(
          fontSize: 20,
          color: Colors.black,
          height: 1.5,
        ),
      ),
    );
  }
}
