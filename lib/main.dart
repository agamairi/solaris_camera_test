import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/io.dart';

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
        CameraController(cameras[selectedCameraIndex], ResolutionPreset.medium);
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

  Future<void> sendFrame(CameraImage img) async {
    try {
      Uint8List bytes = Uint8List.fromList(
          img.planes[0].bytes); // Get the byte data from the CameraImage
      String encoded =
          base64Encode(bytes); // Encode the byte data as a base64 string
      channel.sink.add(encoded); // Send the encoded data through the WebSocket
    } catch (e) {
      print('Error: ${e.toString()}');
    }
  }

  void switchCamera() {
    selectedCameraIndex = selectedCameraIndex < cameras.length - 1
        ? selectedCameraIndex + 1
        : 0; // Switch to the next camera
    CameraController newController =
        CameraController(cameras[selectedCameraIndex], ResolutionPreset.medium);
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
