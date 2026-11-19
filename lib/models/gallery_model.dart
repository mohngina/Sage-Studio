import 'package:flutter/material.dart';

class GalleryItem {
  final String id;
  final String title;
  final String category;
  final String image;
  final String description;
  final String year;
  final Color accentColour;
  final String surfaceColorHex;
  final bool featured;
  final String storyDetails;

  const GalleryItem({
    required this.id,
    required this.title,
    required this.category,
    required this.image,
    required this.description,
    required this.year,
    required this.accentColour,
    this.surfaceColorHex = '#E6E3E2',
    this.featured = false,
    required this.storyDetails,
  });
}
