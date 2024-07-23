import 'package:dissonantapp2/widgets/grainy_background_widget.dart';
import 'package:flutter/material.dart';
import 'order_screen.dart';
import 'mymusic_screen.dart';
import 'profile_screen.dart';
import '../widgets/bottom_navigation_widget.dart'; // Import the BottomNavigationWidget
import '../widgets/carousel_widget.dart';

class HomeScreen extends StatefulWidget {
  final List<String> imgList = [
    'assets/cd_carousel/hcd003.png',
    'assets/cd_carousel/hcd004.png',
    'assets/cd_carousel/hcd005.png',
    'assets/cd_carousel/hcd006.png',
    'assets/cd_carousel/hcd007.png',
    'assets/cd_carousel/hcd008.png',
    'assets/cd_carousel/hcd009.png',
    'assets/cd_carousel/hcd010.png',
    'assets/cd_carousel/hcd011.png',
    'assets/cd_carousel/hcd012.png',
    'assets/cd_carousel/hcd013.png',
    'assets/cd_carousel/hcd014.png',
    'assets/cd_carousel/hcd015.png',
    'assets/cd_carousel/hcd016.png',
    'assets/cd_carousel/hcd017.png',
    // Add more image paths manually here
  ];

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: CarouselWidget(imgList: widget.imgList),
            ),
            Center(
              child: Text(
                'Welcome to Dissonant',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
            // Add other widgets for your homepage here
          ],
        ),
      ),
      OrderScreen(),
      MyMusicScreen(),
      ProfileScreen(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundWidget(
        child: _pages[_selectedIndex],
      ),

    );
  }
}