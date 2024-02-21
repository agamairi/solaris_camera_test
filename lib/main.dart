import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  print("Available cameras: $cameras");
  runApp(const CameraApp());
}

class CameraApp extends StatefulWidget {
  const CameraApp({Key? key}) : super(key: key);

  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  late CameraController controller;
  late String videoPath;
  bool isRecording = false;

  @override
  void initState() {
    super.initState();
    print("Initializing camera controller...");
    controller = CameraController(cameras[1], ResolutionPreset.max);
    controller.initialize().then((_) {
      if (!mounted) {
        print("Widget not mounted, returning early from initState.");
        return;
      }
      print("Camera controller initialized.");
      setState(() {});
    }).catchError((e) {
      print("Failed to initialize camera controller: $e");
    });
  }

  Future<void> startVideoRecording() async {
    if (controller.value.isInitialized && !controller.value.isRecordingVideo) {
      print("Starting video recording...");
      // Get the directory to store the video
      final Directory appDirectory = await getApplicationDocumentsDirectory();
      final String videoDirectory = '${appDirectory.path}/Videos';
      await Directory(videoDirectory).create(recursive: true);
      final String currentTime =
          DateTime.now().millisecondsSinceEpoch.toString();
      videoPath = '$videoDirectory/${currentTime}.mp4';
      print("Video path: $videoPath");

      // Start recording
      try {
        await controller.startVideoRecording();
        print("Video recording started.");
        setState(() {
          isRecording = true;
        });
      } catch (e) {
        print("Error starting video recording: $e");
      }
    } else {
      print("Camera not initialized or already recording.");
    }
  }

  Future<void> stopVideoRecording() async {
    if (controller.value.isRecordingVideo) {
      print("Stopping video recording...");
      try {
        await controller.stopVideoRecording();
        print("Video recording stopped. Video saved to: $videoPath");
        setState(() {
          isRecording = false;
        });
      } catch (e) {
        print("Error stopping video recording: $e");
      }
    } else {
      print("Video recording was not in progress.");
    }
  }

  @override
  void dispose() {
    print("Disposing camera controller...");
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      print("Camera controller is not initialized for build.");
      return Container();
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: CameraPreview(controller),
        floatingActionButton: FloatingActionButton(
          onPressed: isRecording ? stopVideoRecording : startVideoRecording,
          child: Icon(isRecording ? Icons.stop : Icons.videocam),
        ),
      ),
    );
  }
}
