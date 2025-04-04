import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

List<Map<String,dynamic>> transactionsData = [
  {
    'icon': const FaIcon(FontAwesomeIcons.burger,color: Colors.white,),
    'color': Colors.yellow[700],
    'name': 'Food',
    'totalAmount': '-\$40.00',
    'date': 'Today'
  },
  {
    'icon': const FaIcon(FontAwesomeIcons.bagShopping,color: Colors.white),
    'color': Colors.purple,
    'name': 'Shopping',
    'totalAmount': '-\$70.00',
    'date': 'Today'
  },
  {
    'icon': const FaIcon(FontAwesomeIcons.heart,color: Colors.white),
    'color': Colors.green,
    'name': 'Shopping',
    'totalAmount': '-\$230.00',
    'date': 'Yesterday'
  },
  {
    'icon': const FaIcon(FontAwesomeIcons.plane,color: Colors.white),
    'color': Colors.blue,
    'name': 'Treavel',
    'totalAmount': '-\$730.00',
    'date': 'Today'
  },


];