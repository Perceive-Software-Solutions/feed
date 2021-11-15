import 'package:example/widgets/multi_feed.dart';
import 'package:example/widgets/single_feed.dart';
import 'package:example/widgets/sliding_sheet.dart';
import 'package:example/widgets/swipe_feed.dart';
import 'package:flutter/material.dart';
import 'package:sliding_sheet/sliding_sheet.dart';

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

    // void showAsBottomSheet() async {
    //   await showSlidingBottomSheet(
    //     context,
    //     builder: (context) {
    //       return SlidingSheetDialog(
    //         controller: sheetController,
    //         // controller: sheetController,
    //         // color: Colors.transparent,
    //         // extendBody: true,
    //         // cornerRadius: 32,
    //         // cornerRadiusOnFullscreen: 0,

    //         // //Specifies the snapping for the sliding sheet
    //         snapSpec: const SnapSpec(
    //           initialSnap: 0.7,
    //           snappings: [0.0, 0.7, 1.0],
    //         ),
    //         // headerBuilder: (context, state){
    //         //   return Container(
    //         //     color: Colors.white,
    //         //     height: 100,
    //         //     width: MediaQuery.of(context).size.width,
    //         //     child: const Center(child: Text('Header', style: TextStyle(fontSize: 12, color: Colors.black),)),
    //         //   );
    //         // },
    //         // builder: (context, state) {
              
    //           // return SizedBox(
    //           //   height: MediaQuery.of(context).size.height,
    //           //   child: const MultiFeedExample()
    //           // );
    //             // child: ListView.builder(
    //             //   controller: controller,
    //             //   itemCount: 50,
    //             //   itemBuilder: (context, i){
    //             //     return SizedBox(
    //             //       height: 30,
    //             //       child: Text(i.toString(), style: const TextStyle(fontSize: 16))
    //             //     );
    //             //   },
    //             // )
    //             // )
    //         // },
    //         customBuilder: (context, controller, sheet){
    //           return SingleFeedExample(controller: controller);
    //         }
    //       );
    //     }
    //   );
    // }

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
                        builder: (c) => const SlidingSheetExample(),
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
