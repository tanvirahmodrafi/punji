import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:punji/data/data.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.yellow[700],
                          ),
                        ), // BoxDecoration
                        Icon(
                          CupertinoIcons.person_fill,
                          color: Colors.yellow[800],
                        ), // Icon
                      ],
                    ), // Stack
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome!",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ), // Text
                        Text(
                          "Tanvir Ahmod",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ], // Row (Stack + Text)
                ),
                // Settings Button
                IconButton(
                  icon: Icon(
                    CupertinoIcons.settings,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () {
                    // Your settings action goes here
                    //print("Settings clicked");
                  },
                ),
              ], // Row
            ),
            SizedBox(height: 20,),
            Container(
              width:double.infinity,
              height: MediaQuery.of(context).size.width/2,
              decoration:BoxDecoration(
                  gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.tertiary,
                        Theme.of(context).colorScheme.secondary,
                        Theme.of(context).colorScheme.primary,
                      ],
                      transform: const GradientRotation(pi / 4)
                  ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 4,
                    color: Colors.grey.shade400,
                    offset: Offset(5, 5)
                  )
                ]
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                      "Total Balance",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12,),
                  const Text(
                      '\$ 400.00',
                    style: TextStyle(
                      fontSize: 40,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12,horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 25,
                              height: 25,
                              decoration: const BoxDecoration(
                                  color: Colors.white30,
                                  shape: BoxShape.circle
                              ),
                              child: const Center(
                                child: Icon(
                                  CupertinoIcons.arrow_down,
                                  size: 12,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8,),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Income",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                Text(
                                  '\$ 400.00',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              width: 25,
                              height: 25,
                              decoration: const BoxDecoration(
                                  color: Colors.white30,
                                  shape: BoxShape.circle
                              ),
                              child: const Center(
                                child: Icon(
                                  CupertinoIcons.arrow_up,
                                  size: 12,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8,),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Expanses",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                Text(
                                  '\$ 0.00',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 40,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    'Transactions',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () {

                  },
                  child: Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.outline,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 20,),
            Expanded(
              child: ListView.builder(
                itemCount: transactionsData.length,
                itemBuilder: (context, int i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      height: 50,
                                      width: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.yellow[700],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Icon(
                                      Icons.food_bank_outlined,
                                      color: Colors.white,
                                    )
                                  ],
                                ),
                                const SizedBox(width: 16,),
                                Text(
                                  'Food',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),

                                // Add more widgets to Row if needed
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  '-\$40',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                Text(
                                  'Today',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.outline,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            )
                          ]
                        ),
                      ),
                    ),
                  );
                },
              ),
            )


          ], // Column
        ),
      ),
    );
  }
}
