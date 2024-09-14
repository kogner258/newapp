import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class CarouselWidget extends StatelessWidget {
  final List<String> imgList;

  CarouselWidget({required this.imgList});

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      options: CarouselOptions(
        height: 300,  // Increase the height as needed
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.5,
        aspectRatio: 2.0,
        initialPage: 0,
      ),
      items: imgList.map((item) => Container(
        margin: EdgeInsets.all(5.0),
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(5.0)),
          child: Image.asset(
            item,
            fit: BoxFit.contain,  // Use BoxFit.contain to keep the entire image visible
            width: 1000.0,
          ),
        ),
      )).toList(),
    );
  }
}