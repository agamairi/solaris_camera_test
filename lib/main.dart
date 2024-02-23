import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/io.dart';
import 'package:image/image.dart' as img;

// List of available cameras
late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras(); // Get the list of available cameras
  } catch (e) {
    print('Error: ${e.toString()}');
  }
  runApp(CameraApp());
}

class CameraApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController
      controller; // Camera controller for managing camera operations
  late IOWebSocketChannel channel; // WebSocket channel for sending image data
  bool isStreaming = false; // Flag to track if the image stream is active
  int selectedCameraIndex = 0; // Index of the currently selected camera

  @override
  void initState() {
    super.initState();
    controller =
        CameraController(cameras[selectedCameraIndex], ResolutionPreset.low);
    controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    }).catchError((error) {
      print('Error: ${error.toString()}');
    });
    try {
      channel = IOWebSocketChannel.connect(
          'ws://192.168.50.99:8080'); // Connect to the WebSocket server
    } catch (e) {
      print('Error: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    controller.dispose();
    channel.sink.close();
    super.dispose();
  }

  Future<void> sendFrame(CameraImage image) async {
    try {
      final img.Image rgbaImage = img.Image(
          width: image.width, height: image.height); // Create empty image

      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final int pixel =
              image.planes[0].bytes[y * image.width + x]; // Get pixel value
          final int r = (pixel >> 16) & 0xFF;
          final int g = (pixel >> 8) & 0xFF;
          final int b = pixel & 0xFF;
          rgbaImage.setPixelRgba(x, y, r, g, b, 255); // Set pixel color
        }
      }

      final List<int> png = img.encodePng(rgbaImage);
      final String encoded = base64Encode(png);
      channel.sink.add(encoded);
    } catch (e) {
      print('Error: ${e.toString()}');
    }
  }

  void switchCamera() {
    selectedCameraIndex = selectedCameraIndex < cameras.length - 1
        ? selectedCameraIndex + 1
        : 0; // Switch to the next camera
    CameraController newController =
        CameraController(cameras[selectedCameraIndex], ResolutionPreset.low);
    newController.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        controller =
            newController; // Update the camera controller with the new camera
      });
    }).catchError((error) {
      print('Error: ${error.toString()}');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) return Container();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Solaris Test",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: CameraPreview(controller),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            FloatingActionButton(
              onPressed: switchCamera,
              child: Icon(Icons.switch_camera),
              heroTag: null, // Required for multiple FABs
            ),
            FloatingActionButton(
              onPressed: () {
                setState(() => isStreaming = !isStreaming);
                isStreaming
                    ? controller.startImageStream(sendFrame)
                    : controller.stopImageStream();
              },
              backgroundColor:
                  isStreaming ? Colors.red : Theme.of(context).primaryColor,
              heroTag: null, // Required for multiple FABs
              child: Icon(isStreaming ? Icons.stop : Icons.videocam),
            ),
          ],
        ),
      ),
    );
  }
}
