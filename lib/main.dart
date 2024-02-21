import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:camera/camera.dart';

List<CameraDescription>? cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final channel = IOWebSocketChannel.connect('ws://192.168.50.99:8080');
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
              Form(
                child: TextFormField(
                  decoration: InputDecoration(labelText: 'Send a message'),
                  onFieldSubmitted: (String value) async {
                    channel.sink.add(value);
                  },
                ),
              ),
              StreamBuilder(
                stream: channel.stream,
                builder: (context, snapshot) {
                  return Text(snapshot.hasData ? '${snapshot.data}' : '');
                },
              ),
              FutureBuilder<void>(
                future: controller.initialize(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return CameraPreview(controller);
                  } else {
                    return Center(child: CircularProgressIndicator());
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
