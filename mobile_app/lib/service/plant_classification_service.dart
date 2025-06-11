import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:smart_irigation/entities/entities.dart';
import 'package:uuid/uuid.dart';

class PlantClassificationService {
  // Ganti dari 127.0.0.1 ke IP komputer Anda
  static const String _baseUrl = 'http://localhost:8000';
  final _uuid = const Uuid();
  
  Future<PlantEntity?> classifyPlant(dynamic imageData) async {
    try {
      final uri = Uri.parse('$_baseUrl/predict');
      final request = http.MultipartRequest('POST', uri);
      
      // Platform-specific file handling
      if (kIsWeb && imageData is Uint8List) {
        // For web platform - menggunakan bytes langsung
        final multipartFile = http.MultipartFile.fromBytes(
          'file',
          imageData,
          filename: 'image.jpg',
        );
        request.files.add(multipartFile);
      } else if (imageData is File) {
        // For mobile/desktop platforms
        final multipartFile = await http.MultipartFile.fromPath(
          'file',
          imageData.path,
        );
        request.files.add(multipartFile);
      } else {
        throw Exception('Unsupported image data type');
      }
      
      // Set timeout untuk request
      final client = http.Client();
      try {
        final streamedResponse = await client.send(request).timeout(
          const Duration(seconds: 30),
        );
        final response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          return PlantEntity(
            id: _uuid.v4(),
            name: data['prediction'],
            type: data['prediction'],
            confidence: data['confidence'],
            detectedAt: DateTime.now(),
            imageUrl: (kIsWeb && imageData is Uint8List) ? 'web_image' : (imageData as File).path,
          );
        } else {
          throw Exception('Failed to classify plant: ${response.statusCode} - ${response.body}');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      throw Exception('Error classifying plant: $e');
    }
  }
  
  Future<String?> explainWithLime(dynamic imageData) async {
    try {
      final uri = Uri.parse('$_baseUrl/explain/lime');
      final request = http.MultipartRequest('POST', uri);
      
      // Platform-specific file handling
      if (kIsWeb && imageData is Uint8List) {
        final multipartFile = http.MultipartFile.fromBytes(
          'file',
          imageData,
          filename: 'image.jpg',
        );
        request.files.add(multipartFile);
      } else if (imageData is File) {
        final multipartFile = await http.MultipartFile.fromPath(
          'file',
          imageData.path,
        );
        request.files.add(multipartFile);
      } else {
        throw Exception('Unsupported image data type');
      }
      
      final client = http.Client();
      try {
        final streamedResponse = await client.send(request).timeout(
          const Duration(seconds: 30),
        );
        final response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return data['message'];
        } else {
          throw Exception('Failed to get LIME explanation: ${response.statusCode} - ${response.body}');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      throw Exception('Error getting LIME explanation: $e');
    }
  }
  
  Future<String?> explainWithShap(dynamic imageData) async {
    try {
      final uri = Uri.parse('$_baseUrl/explain/shap');
      final request = http.MultipartRequest('POST', uri);
      
      // Platform-specific file handling
      if (kIsWeb && imageData is Uint8List) {
        final multipartFile = http.MultipartFile.fromBytes(
          'file',
          imageData,
          filename: 'image.jpg',
        );
        request.files.add(multipartFile);
      } else if (imageData is File) {
        final multipartFile = await http.MultipartFile.fromPath(
          'file',
          imageData.path,
        );
        request.files.add(multipartFile);
      } else {
        throw Exception('Unsupported image data type');
      }
      
      final client = http.Client();
      try {
        final streamedResponse = await client.send(request).timeout(
          const Duration(seconds: 30),
        );
        final response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return data['message'];
        } else {
          throw Exception('Failed to get SHAP explanation: ${response.statusCode} - ${response.body}');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      throw Exception('Error getting SHAP explanation: $e');
    }
  }
  
  // Mendapatkan pengaturan penyiraman berdasarkan jenis tanaman
  Map<String, dynamic> getIrrigationSettings(String plantType) {
    switch (plantType.toLowerCase()) {
      case 'cactus':
        return {
          'lowerThreshold': 20.0,
          'upperThreshold': 40.0,
          'pumpDuration': 5.0,
          'automaticMode': true,
        };
      case 'tomato':
        return {
          'lowerThreshold': 60.0,
          'upperThreshold': 80.0,
          'pumpDuration': 15.0,
          'automaticMode': true,
        };
      case 'spinach':
        return {
          'lowerThreshold': 70.0,
          'upperThreshold': 85.0,
          'pumpDuration': 12.0,
          'automaticMode': true,
        };
      case 'chili':
        return {
          'lowerThreshold': 50.0,
          'upperThreshold': 70.0,
          'pumpDuration': 10.0,
          'automaticMode': true,
        };
      case 'monstera':
        return {
          'lowerThreshold': 55.0,
          'upperThreshold': 75.0,
          'pumpDuration': 8.0,
          'automaticMode': true,
        };
      default:
        return {
          'lowerThreshold': 50.0,
          'upperThreshold': 70.0,
          'pumpDuration': 10.0,
          'automaticMode': true,
        };
    }
  }
}