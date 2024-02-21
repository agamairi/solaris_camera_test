import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:camera/camera.dart';

// List to store available cameras
List<CameraDescription>? cameras;

Future<void> main() async {
  // flutter binding initialize
  WidgetsFlutterBinding.ensureInitialized();
  // getting list of available cameras
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // creating a web-socket connection - removed my ip for github
    final channel = IOWebSocketChannel.connect('ws://<my_ip_was_here>:8080');
    final CameraController controller =
        CameraController(cameras![0], ResolutionPreset.medium);

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Solaris Test'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // creating a form to send message to server
              Form(
                child: TextFormField(
                  decoration: InputDecoration(labelText: 'Send a message'),
                  onFieldSubmitted: (String value) async {
                    channel.sink.add(value);
                  },
                ),
              ),
              // stream builder to display messages received
              StreamBuilder(
                stream: channel.stream,
                builder: (context, snapshot) {
                  return Text(snapshot.hasData ? '${snapshot.data}' : '');
                },
              ),
              // creating future builder to access the camera.
              FutureBuilder<void>(
                future: controller.initialize(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    // display if camera initialized
                    return CameraPreview(controller);
                  } else {
                    // only display if camera not initialized
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
