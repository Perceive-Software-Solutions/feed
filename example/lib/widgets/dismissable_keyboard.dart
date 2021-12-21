import 'package:flutter/material.dart';
import 'package:flutter_interactive_keyboard/flutter_interactive_keyboard.dart';

class DismissableKeyboard extends StatefulWidget {
  const DismissableKeyboard({ Key? key }) : super(key: key);

  @override
  _DismissableKeyboardState createState() => _DismissableKeyboardState();
}

class _DismissableKeyboardState extends State<DismissableKeyboard> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text('Interactive Keyboard'),
        ),
        body: Container(
          margin: EdgeInsets.only(top:100),
          child: Column(
            children: <Widget>[
              TextField(
                keyboardAppearance: Brightness.dark,
              ),
              Expanded(
                child: KeyboardManagerWidget(
                  onKeyboardClose: (){
                    print("keyboardClose");
                  },
                  onKeyboardOpen: () {
                    print("keyboardOpen");
                  },
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for(int i = 0; i < 100; i++)
                          Text("element ${i}")
                      ],
                    ),
                  ),
                )
              )
            ],
          ),
        ),
      ),
    );
  }
}