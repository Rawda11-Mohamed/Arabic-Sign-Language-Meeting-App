import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

/// Camera preview widget with permission handling
class CameraPreviewWidget extends StatefulWidget {
  final bool isEnabled;
  final CameraLensDirection? preferredLensDirection;

  /// Optional callback invoked when the internal [CameraController]
  /// is initialized and ready, or when it is disposed (null).
  /// This allows parent widgets to use the same controller (e.g.,
  /// for taking pictures or analysis) and react when it is no longer usable.
  final void Function(CameraController? controller)? onControllerReady;

  const CameraPreviewWidget({
    super.key,
    required this.isEnabled,
    this.preferredLensDirection = CameraLensDirection.front,
    this.onControllerReady,
  });

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _hasPermission = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.isEnabled) {
      _initializeCamera();
    }
  }

  @override
  void didUpdateWidget(CameraPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEnabled != oldWidget.isEnabled) {
      if (widget.isEnabled) {
        _initializeCamera();
      } else {
        _disposeCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
    // Request camera permission
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      setState(() {
        _hasPermission = false;
        _errorMessage = 'Camera permission denied';
      });
      return;
    }

    setState(() {
      _hasPermission = true;
    });

    try {
      // Get available cameras
      final cameras = await availableCameras();
      
      // Find preferred camera (front by default)
      CameraDescription? selectedCamera;
      if (widget.preferredLensDirection != null) {
        selectedCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == widget.preferredLensDirection,
          orElse: () => cameras.first,
        );
      } else {
        selectedCamera = cameras.first;
      }

      // Initialize camera controller
      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false, // Audio handled separately for meetings
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _errorMessage = null;
        });

        // Notify parent that controller is ready
        if (widget.onControllerReady != null && _controller != null) {
          widget.onControllerReady!(_controller);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _errorMessage = 'Failed to initialize camera: $e';
        });
      }
    }
  }

  void _disposeCamera() {
    _controller?.dispose();
    _controller = null;
    setState(() {
      _isInitialized = false;
    });

    // Inform parent that controller is no longer available
    if (widget.onControllerReady != null) {
      widget.onControllerReady!(null);
    }
  }

  @override
  void dispose() {
    _disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEnabled) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.videocam_off, size: 80, color: Colors.white70),
        ),
      );
    }

    if (!_hasPermission) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 60, color: Colors.white70),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Camera permission required',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null || !_controller!.value.isInitialized) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white70),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CameraPreview(_controller!),
    );
  }
}

