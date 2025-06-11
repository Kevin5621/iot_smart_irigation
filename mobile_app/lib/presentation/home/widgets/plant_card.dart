import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:smart_irigation/providers/app_provider.dart';

class PlantCard extends StatelessWidget {
  const PlantCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final plant = provider.currentPlant;
        
        return GlassmorphicContainer(
          width: double.infinity,
          height: plant != null ? 200 : 120,
          borderRadius: 20,
          blur: 10,
          alignment: Alignment.center,
          border: 2,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFffffff).withOpacity(0.1),
              const Color(0xFFFFFFFF).withOpacity(0.05),
            ],
            stops: const [0.1, 1],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.5),
              Colors.white.withOpacity(0.2),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: plant != null
                ? _buildPlantInfo(plant)
                : _buildEmptyState(),
          ),
        );
      },
    );
  }
  
  Widget _buildPlantInfo(plant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.eco,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              'Plant Detected',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.5),
                ),
              ),
              child: Text(
                '${(plant.confidence * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Plant Image
            if (plant.imageUrl != null)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildPlantImage(plant.imageUrl!),
                ),
              ),
            const SizedBox(width: 16),
            // Plant Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Type: ${plant.type}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Detected: ${_formatDateTime(plant.detectedAt)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: const Text(
            '🌱 Irrigation settings auto-updated based on plant type',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.camera_alt_outlined,
          color: Colors.white.withOpacity(0.7),
          size: 28, // Reduced from 32
        ),
        const SizedBox(height: 8), // Reduced from 12
        Text(
          'No Plant Detected',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14, // Reduced from 16
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2), // Reduced from 4
        Flexible( // Added Flexible to prevent overflow
          child: Text(
            'Tap the camera button to scan a plant',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11, // Reduced from 12
            ),
            textAlign: TextAlign.center,
            maxLines: 2, // Added maxLines
            overflow: TextOverflow.ellipsis, // Added overflow handling
          ),
        ),
      ],
    );
  }
  
  Widget _buildPlantImage(String imageUrl) {
    if (kIsWeb) {
      // For web platform, show a placeholder icon since we can't display file images
      return Container(
        color: Colors.green.withOpacity(0.3),
        child: const Icon(
          Icons.eco,
          color: Colors.white,
          size: 30,
        ),
      );
    } else {
      // For mobile/desktop platforms, use Image.file
      return Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.withOpacity(0.3),
            child: const Icon(
              Icons.image_not_supported,
              color: Colors.white54,
              size: 30,
            ),
          );
        },
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}