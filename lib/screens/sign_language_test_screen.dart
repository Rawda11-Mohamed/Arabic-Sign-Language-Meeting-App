import 'package:flutter/material.dart';
import 'package:meeting/services/sign_language_service.dart';
import 'package:meeting/services/sign_language_api_service.dart';
import 'package:meeting/widgets/app_button.dart';

/// Test screen for sign language API integration
class SignLanguageTestScreen extends StatefulWidget {
  const SignLanguageTestScreen({super.key});

  @override
  State<SignLanguageTestScreen> createState() => _SignLanguageTestScreenState();
}

class _SignLanguageTestScreenState extends State<SignLanguageTestScreen> {
  final _signLanguageService = SignLanguageService();
  bool _isLoading = false;
  String? _statusMessage;

  @override
  void dispose() {
    _signLanguageService.stopRecognition();
    super.dispose();
  }

  Future<void> _checkApiHealth() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking API connection...\nURL: ${SignLanguageApiService.currentUrl}';
    });

    try {
      final health = await SignLanguageApiService.checkHealth();
      setState(() {
        final modelLoaded = health['model_loaded'] ?? false;
        final modelInfo = health['model_info'] ?? {};
        final modelExists = health['model_exists'] ?? false;
        
        String message = '✓ API Connected!\n\n';
        message += 'Status: ${health['status']}\n';
        message += 'Model Loaded: ${modelLoaded ? 'Yes' : 'No'}\n';
        message += 'Model File Exists: ${modelExists ? 'Yes' : 'No'}\n';
        
        if (modelLoaded && modelInfo['input_shape'] != null) {
          message += '\nModel Info:\n';
          message += 'Input Shape: ${modelInfo['input_shape']}\n';
          if (modelInfo['num_classes'] != null) {
            message += 'Classes: ${modelInfo['num_classes']}';
          }
        } else if (!modelExists) {
          message += '\n⚠ Model file not found.\n';
          message += 'Place sign_language_model.h5 in flask_api/';
        }
        
        _statusMessage = message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Connection Failed\n\n${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Language Test'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // API Status
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'API Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _statusMessage ?? 'Not checked',
                        style: TextStyle(
                          color: _statusMessage?.contains('Error') == true
                              ? Colors.red
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: 'Check API Health',
                        onPressed: _checkApiHealth,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Prediction Display
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Prediction',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ValueListenableBuilder<String>(
                        valueListenable: _signLanguageService.translatedText,
                        builder: (context, text, child) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              text.isEmpty ? 'No prediction yet' : text,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      ValueListenableBuilder<int?>(
                        valueListenable: _signLanguageService.currentPrediction,
                        builder: (context, prediction, child) {
                          if (prediction == null) return const SizedBox.shrink();
                          return ValueListenableBuilder<double?>(
                            valueListenable: _signLanguageService.confidence,
                            builder: (context, confidence, child) {
                              return Text(
                                'Class: $prediction${confidence != null ? ' | Confidence: ${(confidence * 100).toStringAsFixed(1)}%' : ''}',
                                style: const TextStyle(fontSize: 16),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Error Display
              ValueListenableBuilder<String?>(
                valueListenable: _signLanguageService.errorMessage,
                builder: (context, error, child) {
                  if (error == null) return const SizedBox.shrink();
                  return Card(
                    color: Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              error,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Action Buttons
              AppButton(
                label: 'Capture from Camera',
                icon: Icons.camera_alt,
                onPressed: () {
                  _signLanguageService.captureAndPredict();
                },
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Select from Gallery',
                icon: Icons.photo_library,
                isOutlined: true,
                onPressed: () {
                  _signLanguageService.selectAndPredict();
                },
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<bool>(
                valueListenable: ValueNotifier(_signLanguageService.isRecognizing),
                builder: (context, isRecognizing, child) {
                  return AppButton(
                    label: isRecognizing ? 'Stop Recognition' : 'Start Continuous Recognition',
                    icon: isRecognizing ? Icons.stop : Icons.play_arrow,
                    isOutlined: isRecognizing,
                    onPressed: () {
                      if (isRecognizing) {
                        _signLanguageService.stopRecognition();
                      } else {
                        _signLanguageService.startRecognition();
                      }
                      setState(() {}); // Refresh to update button state
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

