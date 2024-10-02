import 'dart:ui';

import 'package:better_flutter/frame/frame.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  FragmentShader? _shader;

  Future<void> _loadShader() async {
    final asset = await FragmentProgram.fromAsset('shaders/noise_shader.frag');
    final shader = asset.fragmentShader();
    shader.setFloat(0, 100);
    shader.setFloat(1, 100);
    setState(() {
      _shader = shader;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(builder: (context) {
        return Scaffold(
          body: Center(
            child: Stack(
              children: [
                // Frame(
                //   style: Style(
                //     backgroundColor: Colors.red,
                //     borderRadius: BorderRadius.circular(0),
                //   ),
                //   box: BoxModel(
                //     margin: const EdgeInsets.all(12),
                //     height: 200,
                //     width: 200,
                //   ),
                // ),
                Frame(
                  style: Style(
                    backgroundColor: Colors.green,
                    border: StyleBorder(
                      cornerSmoothing: 0.6,
                      radius: BorderRadius.circular(24),
                      color: Colors.blue,
                      width: 4,
                      dashPattern: const [20, 10],
                      strokeAlign: BorderSide.strokeAlignOutside,
                      shader: _shader,
                      gradient: const LinearGradient(
                        colors: [Colors.red, Colors.blue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  box: BoxModel(
                    margin: const EdgeInsets.all(12),
                    height: 200,
                    width: 200,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
