import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:punji/screens/home/views/main_screen.dart';

import '../../stats/stats.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  int index = 0;
  late Color selectedItem = Colors.blueAccent;
  Color unSelectedItem = Colors.grey;

  // @override
  // void initState() {
  //   selectedItem = Theme.of(context).colorScheme.primary;
  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Bottom Navigation Bar with `onTap` to switch between the screens
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (value) {
            setState(() {
              index = value;
            });

          },
          backgroundColor: Colors.white,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 3,
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                CupertinoIcons.home,
                color: index == 0 ? selectedItem : unSelectedItem,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                CupertinoIcons.settings,
                color: index == 1 ? selectedItem : unSelectedItem,
              ),
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
          width: 100, // Custom width
          height: 100, // Custom height
          decoration: BoxDecoration(
            shape: BoxShape.circle, // Ensures the shape is round
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
                Theme.of(context).colorScheme.tertiary,
              ],
              transform: const GradientRotation(pi / 4),
            ),
          ),
          child: const Icon(
            CupertinoIcons.add,
            color: Colors.white, // Icon color
          ),
        ),
      ),

      // Switch between screens based on selected index
      //body: widgetList[index],
      body: index == 0
      ? MainScreen()
      : StatScreen(),
    );
  }
}
