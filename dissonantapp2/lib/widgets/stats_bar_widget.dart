import 'package:flutter/material.dart';

class StatsBar extends StatelessWidget {
  final int albumsSentBack;
  final int albumsKept;

  StatsBar({required this.albumsSentBack, required this.albumsKept});

  @override
  Widget build(BuildContext context) {
    final totalAlbums = albumsSentBack + albumsKept;
    final double indicatorPosition = totalAlbums == 0
        ? 0.5
        : albumsKept / totalAlbums;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Albums Sent Back: $albumsSentBack',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            Text(
              'Albums Kept: $albumsKept',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
        SizedBox(height: 10),
        Stack(
          children: [
            Container(
              height: 20,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Positioned(
              left: indicatorPosition * MediaQuery.of(context).size.width - 10,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Color(0xFFFFA500), // Orange
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}