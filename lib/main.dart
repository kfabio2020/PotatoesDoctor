import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Potatoes Doctor',
      theme: ThemeData(
        primarySwatch: Colors.green,
       // visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File _selectedFile;
  bool _inProcess = false;
  List _output;

  @override
  void initState() {
    super.initState();
    _inProcess = true;

    loadModel().then((value) {
      setState(() {
        _inProcess = false;
      });
    });
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",
    );
  }

  Widget getImageWidget() {
    if (_selectedFile != null) {
      return Image.file(
        _selectedFile,
        width: 300,
        height: 320,
        fit: BoxFit.cover,
      );
    } else {
      return Image.asset(
        "assets/placeholder.jpg",
        width: 300,
        height: 320,
        fit: BoxFit.cover,
      );
    }
  }

  getImage(ImageSource source) async {
    this.setState(() {
      _inProcess = true;
    });
    File image = await ImagePicker.pickImage(source: source);
    if (image != null) {
      File cropped = await ImageCropper.cropImage(
          sourcePath: image.path,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio16x9,
            CropAspectRatioPreset.ratio4x3,
          ],
          compressQuality: 50,
          maxWidth: 300,
          maxHeight: 320,
          compressFormat: ImageCompressFormat.jpg,
          androidUiSettings: AndroidUiSettings(
              toolbarColor: Colors.green,
              toolbarTitle: "Rogner image",
              statusBarColor: Colors.green,
              backgroundColor: Colors.white,
              toolbarWidgetColor: Colors.white));

      this.setState(() {
        _selectedFile = cropped;
        _inProcess = false;
      });
    } else {
      this.setState(() {
        _inProcess = false;
      });
    }
  }

   classifyImage(File image) async {
     _output = null;
    var output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 2,
      threshold: 0.5,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      _inProcess = false;
      _output = output;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('PotatoesDoctor'),
        ),
        body: SingleChildScrollView(
          child: Stack(
            children: <Widget>[
              Column(
                // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Container(height: 10), // set height
                  getImageWidget(),
                  Container(height: 10), // set height
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      MaterialButton(
                          color: Colors.green,
                          child: Text(
                            "Caméra",
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () {
                            getImage(ImageSource.camera);
                          }),
                      MaterialButton(
                          color: Colors.deepOrange,
                          child: Text(
                            "Périphérique",
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () {
                            getImage(ImageSource.gallery);
                          }),
                      MaterialButton(
                          color: Colors.blueAccent,
                          child: Text(
                            "Diagnostiquer",
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () {
                            classifyImage(_selectedFile);
                          }),
                    ],
                  ),
                  Container(height: 10), // set height
                  /*child: TextField(
                        maxLines: 4,
                        enabled: false,
                        decoration: new InputDecoration(
                            border: new OutlineInputBorder(),
                            hintText: 'Résultat :',
                            hintStyle:
                                TextStyle(fontSize: 20.0, color: Colors.green),
                            suffixStyle: const TextStyle(color: Colors.green)),
                      )*/
                  _output == null ? Text('Resultat') : Text(_output.toString())
                ],
              ),
              (_inProcess)
                  ? Container(
                      color: Colors.white,
                      height: MediaQuery.of(context).size.height * 0.9,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Center()
            ],
          ),
        ));
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }
}
