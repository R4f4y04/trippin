import 'package:flutter/material.dart';

/// Curated 10-color palette for assigning unique colors to trip members.
/// Each member gets a color based on their join order, cycling after 10.
const List<Color> memberColorPalette = [
  Color(0xFF7C4DFF), // Purple
  Color(0xFF3B82F6), // Blue
  Color(0xFF22D3EE), // Cyan
  Color(0xFF4ADE80), // Green
  Color(0xFFFBBF24), // Amber
  Color(0xFFF97316), // Orange
  Color(0xFFEF4444), // Red
  Color(0xFFEC4899), // Pink
  Color(0xFFA78BFA), // Lavender
  Color(0xFF6EE7B7), // Mint
];

/// Returns the color assigned to a member based on their index
/// in the trip's member list.
Color getMemberColor(int index) {
  return memberColorPalette[index % memberColorPalette.length];
}
