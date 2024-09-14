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
            SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('articles')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (!snapshot.hasData) {
                  return Center(child: Text('No news found.'));
                }

                final articles = snapshot.data!.docs;

                return ListView.builder(
                  physics: NeverScrollableScrollPhysics(), // Disable inner scrolling
                  shrinkWrap: true, // Take only necessary space
                  itemCount: articles.length,
                  itemBuilder: (context, index) {
                    var article = articles[index];
                    DateTime articleDate = (article['timestamp'] as Timestamp).toDate();
                    String formattedDate = DateFormat('MM/dd/yyyy').format(articleDate);

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                      color: Colors.transparent,  // Set the background to transparent
                      elevation: 0,  // Remove elevation to make it fully transparent
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ArticleDetailScreen(
                                title: article['title'] ?? 'Untitled',
                                authorName: article['authorName'] ?? 'Unknown Author',
                                authorProfileImageUrl: article['authorProfileImageUrl'] ?? '',
                                content: article['content'] ?? 'No content available.',
                                imageUrl: article['imageUrl'] ?? '',
                                timestamp: articleDate,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                article['title'] ?? 'Untitled',
                                style: TextStyle(
                                  color: Colors.white,  // Keep the text color white
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8.0),
                              Text(
                                article['summary'] ?? '',
                                style: TextStyle(
                                  color: Colors.white70,  // Keep the summary text color white
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8.0),
                              Row(
                                children: [
                                  if ((article['authorProfileImageUrl'] ?? '').isNotEmpty)
                                    CircleAvatar(
                                      backgroundImage: NetworkImage(article['authorProfileImageUrl']),
                                      radius: 16,
                                    ),
                                  if ((article['authorProfileImageUrl'] ?? '').isEmpty)
                                    CircleAvatar(
                                      child: Icon(Icons.person, size: 16),
                                      radius: 16,
                                    ),
                                  SizedBox(width: 8.0),
                                  Text(
                                    article['authorName'] ?? 'Unknown Author',
                                    style: TextStyle(color: Colors.white70),  // Keep author name white
                                  ),
                                  SizedBox(width: 8.0),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(color: Colors.white38),  // Keep date text white
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
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