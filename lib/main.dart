import 'package:flutter/material.dart';
import 'package:drishti/map.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:avatar_glow/avatar_glow.dart';

FlutterBlue bluetooth = FlutterBlue.instance;
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: MyHomePage(title: 'Drishti'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  
  FlutterTts tts;

  stt.SpeechToText _speech;
  bool _isListening = false;
  String _text;
  bool des = false;
  String destination = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    tts = FlutterTts();
    tts.speak('tap on the screen');
    _text = 'speak the place name and then tap on screen';

  }
  @override
  Widget build(BuildContext context) {
   
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GestureDetector(
        onTap: _listen,
              child: Scaffold(
                appBar: AppBar(
                  backgroundColor: Color.fromRGBO(0, 172, 193, 1),
          title: Text('Drishti'),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: AvatarGlow(
          animate: _isListening,
          glowColor: Color.fromRGBO(0, 172, 193, 1),
          endRadius: 75.0,
          duration: const Duration(milliseconds: 2000),
          repeatPauseDuration: const Duration(milliseconds: 100),
          repeat: true,
          child: FloatingActionButton(
            //foregroundColor: Color.fromRGBO(0, 172, 193, 1),
            backgroundColor: Color.fromRGBO(0, 172, 193, 1),
            onPressed: () async{
              _listen();
            },
            child: Icon(_isListening ? Icons.mic : Icons.mic_none),
          ),
        ),
        body: GestureDetector(
          onTap: _listen,
                child: SingleChildScrollView(
            reverse: true,
            child: Container(
              padding: const EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 150.0),
              child: Text(
                _text,
                style: const TextStyle(
                  fontSize: 32.0,
                  color: Colors.black54,
                  fontWeight: FontWeight.w200,
                ),
              ),
            ),
          ),
        ),
        ),
      )
    );
  }


void _listen() async {
  await tts.awaitSpeakCompletion(true);
  await tts.speak(_text);

  if (!_isListening) {
    bool available = await _speech.initialize(
      onStatus: (val) => print('onStatus: $val'),
      onError: (val) => print('onError: $val'),
    );
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) =>
            setState(() {
              _text = val.recognizedWords;
              destination = val.recognizedWords;
            }),
      );
    }
  } else {
    setState(() => _isListening = false);
    _speech.stop();
    print(destination);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>MapPage(destination: destination,),settings: RouteSettings(arguments: [destination])));
  }
}
}