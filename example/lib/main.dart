import 'package:example/widgets/compact_feed.dart';
import 'package:example/widgets/dismissable_keyboard.dart';
import 'package:example/widgets/multi_feed.dart';
import 'package:example/widgets/sliding_feed.dart';
import 'package:example/widgets/swipe_feed.dart';
import 'package:flutter/material.dart';
import 'package:perceive_slidable/sliding_sheet.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  late SheetController sheetController;

  @override
  void initState(){
    sheetController = SheetController();
  }

  @override
  Widget build(BuildContext context) {

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/background.jpg',
            fit: BoxFit.fill,
          ),
        ),
        Positioned.fill(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: Center(
                      child: Text('Feed', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black))
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: Center(
                      child: Text('Contains a Stack feed and a Multi-Feed both supporting asynchronous requests', textAlign: TextAlign.center,)
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Container(
                      height: 1,
                      color: Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  GestureDetector(
                    child: Container(
                      height: 75,
                      child: const Center(
                        child: Text(
                          'Swipe Feed', 
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)
                        ),
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32)
                      ),
                    ),
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SwipeFeedExample()),
                      );
                    },
                  ),
                  Container(
                    height: 1,
                    color: Colors.grey.withOpacity(0.2),
                  ),
                  GestureDetector(
                    child: Container(
                      height: 75,
                      child: const Center(
                        child: Text(
                          'Multi-Feed', 
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)
                        ),
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32)
                      ),
                    ),
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MultiFeedExample()),
                      );
                    },
                  ),
                  Container(
                    height: 1,
                    color: Colors.grey.withOpacity(0.2),
                  ),
                  GestureDetector(
                    child: Container(
                      height: 75,
                      child: const Center(
                        child: Text(
                          'Sliding Sheet Feed', 
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)
                        ),
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32)
                      ),
                    ),
                    onTap: (){
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        enableDrag: false,
                        isDismissible: true,
                        useRootNavigator: false,
                        builder: (c) => const SlidingFeedExample(),
                      );
                    },
                  ),
                  Container(
                    height: 1,
                    color: Colors.grey.withOpacity(0.2),
                  ),
                  GestureDetector(
                    child: Container(
                      height: 75,
                      child: const Center(
                        child: Text(
                          'Compact Feed', 
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)
                        ),
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32)
                      ),
                    ),
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CompactFeedExample()),
                      );
                    },
                  ),
                  Container(
                    height: 1,
                    color: Colors.grey.withOpacity(0.2),
                  ),
                  GestureDetector(
                    child: Container(
                      height: 75,
                      child: const Center(
                        child: Text(
                          'Dismissable Keyboard', 
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)
                        ),
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32)
                      ),
                    ),
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DismissableKeyboard()),
                      );
                    },
                  ),
                  Container(
                    height: 1,
                    color: Colors.grey.withOpacity(0.2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
