import 'package:flutter/material.dart';

class BottomNavigationWidget extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  BottomNavigationWidget({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Image.asset(
            'assets/homeicon.png',
            width: 28,
            height: 32,
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Image.asset(
            'assets/ordericon.png',
            width: 32,
            height: 32,
          ),
          label: 'Order',
        ),
        BottomNavigationBarItem(
          icon: Image.asset(
            'assets/mymusicicon.png',
            width: 32,
            height: 32,
          ),
          label: 'My Music',
        ),
        BottomNavigationBarItem(
          icon: Image.asset(
            'assets/profileicon.png',
            width: 32,
            height: 32,
          ),
          label: 'Profile',
        ),
      ],
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: Colors.orange,
      backgroundColor: Color(0xFF1E1E1E), // Set the background color here
      onTap: onTap,
    );
  }
}
