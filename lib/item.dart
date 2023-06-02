import 'dart:io';

import 'package:flutter/material.dart';
class Item {
  String description;
  DateTime? date;
  File? image;
  TextEditingController controller;
  String? imageUrl; 

  Item({
    required this.description,
    required this.date,
    required this.image,
    required this.controller,
    this.imageUrl, 
  });
}

