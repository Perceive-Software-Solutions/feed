import 'package:example/widgets/multi_feed.dart';
import 'package:example/widgets/single_feed.dart';
import 'package:example/widgets/swipe_feed.dart';
import 'package:feed/util/state/concrete_cubit.dart';
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

  ///Holds the state for sliding sheet extent past the innital extent
  ///Used to rebuild drag dependant values
  late ConcreteCubit<double> sheetExtent;

  //Determines if the scroll is locked
  late ConcreteCubit<bool> scrollLock;

  @override
  void initState(){
    sheetController = SheetController();

    //initialize the extent cubit
    sheetExtent = ConcreteCubit<double>(0.7);

    //Initialize the scroll lock cubit
    scrollLock = ConcreteCubit<bool>(false);
  }

  ///Listens to chanages to the sliding sheet state
  void _sheetStateListener(SheetState state) async {   

    //Close the page when the extent is zero
    if(state.extent == 0.0) {
      if(mounted) {
        Navigator.of(context).pop();
      }
    }
    //Otherwise update the sheetExtent cubit
    else{
      sheetExtent.emit(state.extent);
    }

    
    //If the sheet reaches the max extent, lock the scroll
    if(state.extent == 1.0){
      scrollLock.emit(true);
    }
    //Otherwise if it is locked, unlock it
    else if(scrollLock.state){
      scrollLock.emit(false);
    }
    
  }

  @override
  Widget build(BuildContext context) {

    void showAsBottomSheet() async {
      await showSlidingBottomSheet(
        context,
        builder: (context) {
          return SlidingSheetDialog(
            controller: sheetController,
            color: Colors.transparent,
            extendBody: true,
            cornerRadius: 32,
            cornerRadiusOnFullscreen: 0,
            //Listeners
            listener: _sheetStateListener,
            snapSpec: const SnapSpec(
              initialSnap: 0.7,
              snappings: [0.0, 0.7, 1.0],
            ),
            headerBuilder: (context, state){
              return const SizedBox(
                height: 200,
              );
            },
            builder: (context, state){
              return NotificationListener<ScrollNotification>(
                onNotification: (notification){
                  if(notification is OverscrollNotification){
                    sheetController.snapToExtent(sheetController.state!.extent - (notification.dragDetails!.delta.dy/MediaQuery.of(context).size.height), duration: Duration.zero);
                  }
                  else if(notification is ScrollEndNotification){
                    double extent = sheetExtent.state;
                    // print('ibte ${notification.dragDetails.velociy}');
                    // print(notification.dragDetails);
                    // if(notification.dragDetails!.velocity.pixelsPerSecond.dy > 20){
                    //   sheetController.snapToExtent(0.0, duration: Duration(milliseconds: 200));
                    //   // Navigator.of(context).pop(userNewPost);
                    // }
                    // print('ibte ${extent}');
                    if(extent != 0.7 || extent != 1.0){
                      if(extent >= 0.2 && extent < 0.8){
                        // print('ibte init');
                        sheetController.snapToExtent(0.7);
                      }else if(extent >= 0.8){
                        // print('ibte expand');
                        sheetController.expand();
                      }
                      else{
                        sheetController.collapse();
                        Navigator.of(context).pop();
                      }
                    }
                  }
                  return true;
                },
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: MultiFeedExample(
                    disableScroll: state.extent < 0.7,
                  )
                ),
              );
            }

          );
        }
      );
    }

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
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(builder: (context) => const MultiFeedExample()),
                      // );
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
                      showAsBottomSheet();
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
