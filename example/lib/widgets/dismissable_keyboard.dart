import 'package:flutter/material.dart';

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
                child: SizedBox.shrink(),
              )
            ],
          ),
        ),
      ),
    );
  }
}