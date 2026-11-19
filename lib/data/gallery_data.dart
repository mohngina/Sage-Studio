import 'package:flutter/material.dart';
import '../models/gallery_model.dart';

class GalleryData {
  static const List<GalleryItem> items = [
    GalleryItem(
      id: 'g1',
      title: 'SUCCULENTS',
      category: 'BOTANICAL STUDY',
      image: 'https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?auto=format&fit=crop&w=1000&q=80',
      description:
          'Succulents symbolize enduring and timeless love for they are tenacious plants that store water in their thick leaves and stems.',
      year: '2025',
      accentColour: Color(0xFF690400), // Terracotta/burgundy accent block from mood board
      surfaceColorHex: '#E6E3E2',
      featured: true,
      storyDetails:
          'In this collection, we explore how botanical geometry mirrors hand-molded clay contours. Organic greenery brings tranquil life to structured interior surfaces.',
    ),
    GalleryItem(
      id: 'g2',
      title: 'BURNT ORANGE',
      category: 'MATERIAL PALETTE',
      image: 'https://images.unsplash.com/photo-1540932239986-30128078f3c5?auto=format&fit=crop&w=1000&q=80',
      description:
          'Orange is associated with meanings of joy, warmth, heat, sunshine, enthusiasm, creativity, success, encouragement, freedom and expression.',
      year: '2025',
      accentColour: Color(0xFFCC5600), // Burnt orange accent block
      surfaceColorHex: '#CFD9A3', // Muted sage block
      featured: true,
      storyDetails:
          'Burnt orange represents raw clay fired at peak kiln intensity. Combined with muted sage and brushed brass, it creates quiet luxury with rich visual weight.',
    ),
    GalleryItem(
      id: 'g3',
      title: 'TACTILE EARTH',
      category: 'STUDIO ESSAYS',
      image: 'https://images.unsplash.com/photo-1578749556568-bc2c40e68b61?auto=format&fit=crop&w=1000&q=80',
      description:
          'Unrefined sand stonewares and natural mineral pigments create surfaces that demand touch and reward stillness.',
      year: '2024',
      accentColour: Color(0xFF725D24),
      surfaceColorHex: '#E6E3E2',
      storyDetails:
          'Every curvature in this series was formed by hand wheel throwing without mechanical molds, celebrating human subtle imperfections.',
    ),
    GalleryItem(
      id: 'g4',
      title: 'MINIMAL ARCHITECTURE',
      category: 'SPACE & FORM',
      image: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1000&q=80',
      description:
          'Spatial harmony achieved through generous negative space, natural directional light, and raw architectural ceramic forms.',
      year: '2024',
      accentColour: Color(0xFF111111),
      surfaceColorHex: '#E6E3E2',
      storyDetails:
          'An architectural editorial capturing ceramic objects installed within quiet residential interiors across Copenhagen and Kyoto.',
    ),
  ];
}
