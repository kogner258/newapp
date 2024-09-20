import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dissonantapp2/widgets/grainy_background_widget.dart';
import 'package:flutter/material.dart';
import 'order_screen.dart';
import 'mymusic_screen.dart';
import 'profile_screen.dart';
import '../widgets/bottom_navigation_widget.dart';
import '../widgets/carousel_widget.dart';
import 'article_detail_screen.dart';
import 'package:intl/intl.dart';  // Import the intl package

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
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.all(5.0),
              child: CarouselWidget(imgList: widget.imgList),
            ),
            SizedBox(height: 20),
            BrandingContentWidget(),
            SizedBox(height: 20),
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

class BrandingContentWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0), // Add some horizontal padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Own the music you discover',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.0),
          // Subtitle
          Text(
            'The affordable alternative for those who hate streaming but love music.',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 16.0),
          // Divider or some separator
          Divider(color: Colors.white24),

          SizedBox(height: 8.0),

          Text(
            'How It Works',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.0),
          // Steps
          _buildHowItWorksSteps(),
          SizedBox(height: 16.0),
          // Why Choose Dissonant?
          Text(
            'Dissonant\'s Mission',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.0),
          // Reasons
          _buildWhyChooseDissonant(),
          SizedBox(height: 16.0),
          // Ready to Rediscover Music?
          Divider(color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildHowItWorksSteps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStep(
          number: '1',
          title: 'Tell Us About Yourself',
          description:
              'Fill out a quick form about your musical preferences—your favorite genres, and how adventurous you want your discovery to be.',
        ),
        _buildStep(
          number: '2',
          title: 'Receive a Handpicked CD',
          description:
              'Our music lover curators select a CD tailored just for you and send it straight to your door at no cost.',
        ),
        _buildStep(
          number: '3',
          title: 'Immerse Yourself in the Music',
          description:
              'Throw it in a player, hold the CD, explore the artwork, read the liner notes, truly live with the music.',
        ),
        _buildStep(
          number: '4',
          title: 'Keep It or Return It',
          description:
              'Loving your CD? Opt to purchase and make it a permanent part of your collection. If not, simply use the prepaid shipping label to send it back, no costs involved.',
        ),
      ],
    );
  }

  Widget _buildStep({required String number, required String title, required String description}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhyChooseDissonant() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReason(
          icon: '🌿',
          title: 'Sustainability',
          description:
              'We give secondhand CDs a new life. The best album you\'ve never heard is collecting dust somewhere, and we want to get it to you.',
        ),
        _buildReason(
          icon: '🎧',
          title: 'Authentic Experience',
          description:
              'Streaming has removed the true connection between artist and listener. We want you to hold your favorite albums in your hands.',
        ),
        _buildReason(
          icon: '💰',
          title: 'Affordability',
          description:
              'Discover new music without breaking the bank. Enjoy our service for free and only pay if you decide to keep a CD.',
        ),
      ],
    );
  }

  Widget _buildReason({required String icon, required String title, required String description}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$icon ',
            style: TextStyle(fontSize: 24),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}