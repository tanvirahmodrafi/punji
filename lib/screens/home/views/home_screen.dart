import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:punji/screens/home/views/main_screen.dart';



class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(),
      // Removed the AppBar as per your request

      // ✅ Made the BottomNavigationBar slightly rounded using ClipRRect
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16), // ← rounded top left corner
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 3,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.settings),
              label: 'Setting',
            ),
          ],
        ),
      ),
      
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton.large(
        onPressed: () {},
        shape: const CircleBorder(),
        child: Container(
          width: 100,  // Custom width
          height: 100, // Custom height
          decoration: BoxDecoration(
            shape: BoxShape.circle, // Ensures the shape is round
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
                Theme.of(context).colorScheme.tertiary,
              ],
              transform: const GradientRotation(pi / 4)
            ),
          ),
          child: const Icon(
            CupertinoIcons.add,
            color: Colors.white, // Icon color
          ),
        ),
      ),
      body: const MainScreen(),
    );
  }
}
