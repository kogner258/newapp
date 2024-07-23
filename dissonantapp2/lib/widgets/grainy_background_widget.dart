import 'package:flutter/material.dart';

class BackgroundWidget extends StatelessWidget {
  final Widget child;

  BackgroundWidget({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/grainoverlay.png',
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}