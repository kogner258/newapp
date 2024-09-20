import 'package:flutter/material.dart';

class AlbumDetailsScreen extends StatelessWidget {
  final String albumCoverUrl;
  final String artist;
  final String albumName;
  final String releaseYear;
  final List<String> genres;
  final List<String> similarAlbums;
  final int kept;
  final int returned;
  final double price;
  final int rating;

  const AlbumDetailsScreen({
    required this.albumCoverUrl,
    required this.artist,
    required this.albumName,
    required this.releaseYear,
    required this.genres,
    required this.similarAlbums,
    required this.kept,
    required this.returned,
    required this.price,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2D2D2D), // Dark background
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/grainy_background.png', // Use grainy background for retro feel
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Left section with album cover and stats
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      // Album cover
                      Container(
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.9),
                              offset: Offset(4, 4),
                              blurRadius: 0,
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.9),
                              offset: Offset(6, 6),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Image.network(
                          albumCoverUrl,
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(height: 20),
                      // Kept/Returned/Price
                      _buildStatBlock('Kept', kept.toString()),
                      _buildStatBlock('Returned', returned.toString()),
                      _buildStatBlock('Price', '\$${price.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
                // Right section with album details
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          albumName.toUpperCase(),
                          style: _retroTitleStyle(),
                        ),
                        Text(
                          'Artist: $artist',
                          style: _retroTextStyle(),
                        ),
                        Text(
                          'Release Year: $releaseYear',
                          style: _retroTextStyle(),
                        ),
                        SizedBox(height: 10),
                        // Rating Stars
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < rating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.orange,
                              size: 20,
                            );
                          }),
                        ),
                        SizedBox(height: 20),
                        // Genres
                        Text('Genres:', style: _retroTextStyle()),
                        for (var genre in genres)
                          Row(
                            children: [
                              Icon(Icons.music_note, color: Colors.orange, size: 18),
                              SizedBox(width: 8),
                              Text(genre, style: _retroTextStyle()),
                            ],
                          ),
                        SizedBox(height: 20),
                        // Similar Albums
                        Text('Similar Albums:', style: _retroTextStyle()),
                        for (var similarAlbum in similarAlbums)
                          Row(
                            children: [
                              Icon(Icons.album, color: Colors.orange, size: 
                              18),
                              SizedBox(width: 8),
                              Text(similarAlbum, style: _retroTextStyle()),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build the stat block (Kept, Returned, Price)
  Widget _buildStatBlock(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: _retroTextStyle(),
          ),
          Text(
            value,
            style: _retroTextStyle(),
          ),
        ],
      ),
    );
  }

  // Retro style for headings
  TextStyle _retroTitleStyle() {
    return TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      shadows: [
        Shadow(
          offset: Offset(2, 2),
          color: Colors.black,
        ),
      ],
    );
  }

  // Retro style for normal text
  TextStyle _retroTextStyle() {
    return TextStyle(
      fontSize: 16,
      color: Colors.white,
      shadows: [
        Shadow(
          offset: Offset(1, 1),
          color: Colors.black,
        ),
      ],
    );
  }
}