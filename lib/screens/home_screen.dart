import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dissonantapp2/widgets/grainy_background_widget.dart';
import 'package:flutter/material.dart';
import 'order_screen.dart';
import 'mymusic_screen.dart';
import 'profile_screen.dart';
import '../widgets/bottom_navigation_widget.dart';
import '../widgets/carousel_widget.dart';
import 'article_detail_screen.dart';
import 'package:intl/intl.dart'; // Import the intl package

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
    return SingleChildScrollView(
      child: Column(
        children: [
          // Hero Section
          _buildHeroSection(),
          SizedBox(height: 20),
          // How It Works
          _buildSectionTitle('How It Works'),
          _buildHowItWorksSteps(),
          SizedBox(height: 20),
          // Dissonant's Mission
          _buildSectionTitle('Dissonant\'s Mission'),
          _buildMissionPoints(),
          SizedBox(height: 20),
          // Call to Action
          //_buildCallToAction(),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Own the Music You Discover',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.orangeAccent,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            'The affordable alternative for those who hate streaming but love music.',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: Colors.white24),
          ),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.orangeAccent,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Divider(color: Colors.white24),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksSteps() {
    final steps = [
      {
        'icon': Icons.person,
        'title': 'Tell Us About Yourself',
        'description':
            'Fill out a quick form about your musical preferences—your favorite genres and how adventurous you want your discovery to be.',
      },
      {
        'icon': Icons.local_shipping,
        'title': 'Receive a Handpicked CD',
        'description':
            'Our music lover curators select a CD tailored just for you and send it straight to your door at no cost.',
      },
      {
        'icon': Icons.headset,
        'title': 'Immerse Yourself in the Music',
        'description':
            'Hold the CD, explore the artwork, read the liner notes, truly live with the music.',
      },
      {
        'icon': Icons.swap_horiz,
        'title': 'Keep It or Return It',
        'description':
            'Love it? Keep it for a small fee. If not, use the prepaid shipping label to send it back, no costs involved.',
      },
    ];

    return Column(
      children: steps.map((step) => _buildStepCard(step)).toList(),
    );
  }

  Widget _buildStepCard(Map<String, dynamic> step) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orangeAccent,
          child: Icon(step['icon'], color: Colors.black),
        ),
        title: Text(
          step['title'],
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          step['description'],
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildMissionPoints() {
    final missions = [
      {
        'icon': Icons.eco,
        'title': 'Sustainability',
        'description':
            'We give secondhand CDs a new life. The best album you\'ve never heard is collecting dust somewhere, and we want to get it to you.',
      },
      {
        'icon': Icons.music_note,
        'title': 'Authentic Experience',
        'description':
            'Streaming has removed the true connection between artist and listener. We want you to hold your favorite albums in your hands.',
      },
      {
        'icon': Icons.attach_money,
        'title': 'Affordability',
        'description':
            'Discover new music without breaking the bank. Enjoy our service for free and only pay if you decide to keep a CD.',
      },
    ];

    return Column(
      children: missions.map((mission) => _buildMissionCard(mission)).toList(),
    );
  }

  Widget _buildMissionCard(Map<String, dynamic> mission) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orangeAccent,
          child: Icon(mission['icon'], color: Colors.black),
        ),
        title: Text(
          mission['title'],
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          mission['description'],
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildCallToAction() {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Ready to Rediscover Music?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.orangeAccent,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            'Join Dissonant today and embark on a new musical journey.',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Navigate to sign-up or order page
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text(
              'Sign Up Now',
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
