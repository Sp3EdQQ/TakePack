import 'package:flutter/material.dart';

/// Floating action button to center map on user's location
class CenterLocationButton extends StatelessWidget {
  final VoidCallback onTap;

  const CenterLocationButton({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      shadowColor: Colors.black.withOpacity(0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.my_location,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
