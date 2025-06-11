import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:smart_irigation/entities/entities.dart';
import 'package:uuid/uuid.dart';

class PlantClassificationService {
  static const String _baseUrl = 'http://localhost:8000'; // Ganti dengan IP server Python API
  final _uuid = const Uuid();
  
  Future<PlantEntity?> classifyPlant(File imageFile) async {
    try {
      final uri = Uri.parse('$_baseUrl/predict');
      final request = http.MultipartRequest('POST', uri);
      
      // Tambahkan file gambar ke request
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      );
      request.files.add(multipartFile);
      
      // Kirim request dengan client yang aman untuk web
      final client = kIsWeb ? http.Client() : http.Client();
      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      client.close();
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        return PlantEntity(
          id: _uuid.v4(),
          name: data['prediction'],
          type: data['prediction'],
          confidence: data['confidence'],
          detectedAt: DateTime.now(),
          imageUrl: imageFile.path,
        );
      } else {
        throw Exception('Failed to classify plant: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error classifying plant: $e');
    }
  }
  
  Future<String?> explainWithLime(File imageFile) async {
    try {
      final uri = Uri.parse('$_baseUrl/explain/lime');
      final request = http.MultipartRequest('POST', uri);
      
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      );
      request.files.add(multipartFile);
      
      final client = kIsWeb ? http.Client() : http.Client();
      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      client.close();
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['message'];
      } else {
        throw Exception('Failed to get LIME explanation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting LIME explanation: $e');
    }
  }
  
  Future<String?> explainWithShap(File imageFile) async {
    try {
      final uri = Uri.parse('$_baseUrl/explain/shap');
      final request = http.MultipartRequest('POST', uri);
      
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      );
      request.files.add(multipartFile);
      
      // Kirim request dengan client yang aman untuk web
      final client = kIsWeb ? http.Client() : http.Client();
      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      client.close();
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['message'];
      } else {
        throw Exception('Failed to get SHAP explanation: ${response.statusCode}');
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