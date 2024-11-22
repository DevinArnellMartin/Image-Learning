import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['API_KEY']!,
      authDomain: dotenv.env['AUTH_DOMAIN']!,
      projectId: dotenv.env['PROJECT_ID']!,
      storageBucket: dotenv.env['STORAGE_BUCKET']!,
      messagingSenderId: dotenv.env['MESSAGING_SENDER_ID']!,
      appId: dotenv.env['APP_ID']!,
      measurementId: dotenv.env['MEASUREMENT_ID']!,
    ),
  );
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Labeler',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HPState();
}

class HPState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ML Kit Image Labeler'),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              title: const Text('Image Labeler'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ImageLabelingScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text('Welcome to ML Kit Image Labeler!'),
      ),
    );
  }
}

class ImageLabelingScreen extends StatefulWidget {
  const ImageLabelingScreen({super.key});

  @override
  ImgLabelState createState() => ImgLabelState();
}

class ImgLabelState extends State<ImageLabelingScreen> {
  File? img;
  final picker = ImagePicker();
  List<Map<String, dynamic>> _labels_ = [];

  Future<void> process(File image) async { //processing the image
    final inputImage = InputImage.fromFile(image);
    final labeler = ImageLabeler(options: ImageLabelerOptions());
    final labels = await labeler.processImage(inputImage);

    setState(() {
      _labels_ = labels.map((e) => {'text': e.toString(), 'confidence': e.confidence}).toList();
    });

    labeler.close();
  }

  Future<void> getImg(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      final image = File(pickedFile.path);
      setState(() {
        img = image;
      });
      await process(image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Labeler'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (img != null)
            Image.file(img!, height: 200, width: 200, fit: BoxFit.cover),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => getImg(ImageSource.gallery),
            child: const Text('Select Image'),
          ),
          ElevatedButton(
            onPressed: () => getImg(ImageSource.camera),
            child: const Text('Capture Image'),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _labels_.length,
              itemBuilder: (context, index) {
                final label = _labels_[index];
                return ListTile(
                  title: Text(label['text']),
                  subtitle: Text(
                    'Confidence: ${(label['confidence'] * 100).toStringAsFixed(2)}%',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}