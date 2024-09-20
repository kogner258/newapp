import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class CarouselWidget extends StatelessWidget {
  final List<String> imgList;

  CarouselWidget({required this.imgList});

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      options: CarouselOptions(
        height: 300,  // Increase the height for larger images
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.7,  // Increase to make items take up more space (closer to 1.0 means larger items)
        aspectRatio: 2.0,
        initialPage: 0,
      ),
      items: imgList.map((item) => Container(
        margin: EdgeInsets.all(5.0),
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(5.0)),
          child: Image.asset(
            item,
            fit: BoxFit.contain,  // Change to cover to fill the area while maintaining aspect ratio
            width: 1000.0,
          ),
        ),
      )).toList(),
    );
  }
}