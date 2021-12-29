import 'dart:math';

import 'package:feed/feeds/swipe_feed.dart';
import 'package:feed/util/icon_position.dart';
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

class SwipeFeedExample<T> extends StatefulWidget {
  const SwipeFeedExample({ Key? key }) : super(key: key);

  @override
  _SwipeFeedExampleState createState() => _SwipeFeedExampleState();
}

class _SwipeFeedExampleState<T> extends State<SwipeFeedExample> {

  late SwipeFeedController feedController;

  @override
  void initState() {
    super.initState();
    feedController = SwipeFeedController();
  }

  Future<Tuple2<List<String>, String?>> loadItems(int size, [String? token]) async {
    await Future.delayed(const Duration(seconds: 1));
    return const Tuple2(['Testing1', 'Testing2', 'Testing3'], null);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        floatingActionButton: GestureDetector(
          child: Container(
            height: 75,
            width: 75,
            child: const Icon(Icons.plus_one, size: 20),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(40)
            ),
          ),
          onTap: (){
            feedController.addItem('It Worked !!!!!!');
            // feedController.swipeRight();
          }
        ),
        body: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: 57,
                color: Colors.blue,
                child: Padding(
                  padding: const EdgeInsets.only(right: 34),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      const Text('Swipe-Feed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32)),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                color: Colors.grey[400],
                child: SizedBox.fromSize(size: const Size.fromHeight(49))
              ),
            ),
            Positioned.fill(
              child: SwipeFeed<String>(
                heightOfCard: MediaQuery.of(context).size.height - 57 - 16 - 49 - 13,
                icons: const [Icons.star, Icons.check, Icons.cancel],
                padding: const EdgeInsets.only(top: 57 + 16, left: 8, right: 8, bottom: 49 + 13),
                duration: const Duration(milliseconds: 300),
                iconScale: 0.963,
                iconPadding: const EdgeInsets.only(top: 67, bottom: 5),
                topAlignment: const Alignment(0, -0.055),
                bottomAlignment: const Alignment(0, 0.11),
                startBottomAlignment: const Alignment(0, 0.20),
                startTopAlignment: const Alignment(0, -0.07),
                controller: feedController,
                overlayMaxDuration: const {DismissDirection.endToStart: Duration(seconds: 3), DismissDirection.startToEnd: Duration(seconds: 3)},
                loader: loadItems,
                objectKey: (item){
                  return item.hashCode.toString();
                },
                overrideSwipeAlert: (index, item, direction){
                  if(direction == DismissDirection.down && item == "Testing1"){
                    return true;
                  }
                  return false;
                },
                swipeAlert: (index){
                  return true;
                },
                canExpand: (item){
                  return true;
                },
                overlayBuilder: (forwardAnimation, reverseAnimation, index, item){
                  List colors = [Colors.red, Colors.green, Colors.yellow, Colors.red, Colors.yellow, Colors.indigo];
                  Random random = new Random();
                  return Padding(
                    padding: EdgeInsets.only(left: 100*index.toDouble()),
                    child: Container(
                      height: 300,
                      width: 300,
                      color: colors[random.nextInt(6)],
                      child: MaterialButton(
                        child: Text(item, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 24)),
                        onPressed: (){
                          forwardAnimation(index, true);
                        }
                      )
                    ),
                  );
                },
                noPollsPlaceHolder: GestureDetector(
                  child: Container(
                    decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black, width: 3),
                    ),
                  ),
                  onTap: (){
                    feedController.refresh();
                  },
                ),
                noConnectivityPlaceHolder: GestureDetector(
                  child: Container(
                    height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top -  MediaQuery.of(context).padding.bottom - 62 - 125,
                    decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black, width: 3),
                    ),
                  ),
                  onTap: (){
                    feedController.refresh();
                  },
                ),
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                ),
                childBuilder: (dynamic value, bool isLast, bool isExpanded, void Function() close ) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black, width: 3),
                    ),
                    child: Center(
                      child: Container(
                        color: isExpanded ? Colors.amber : null,
                        child: GestureDetector(
                          onTap: isExpanded ? close : null,
                          child: Column(
                            children: [
                              Text(
                                'value ${isExpanded ? '\n\n Tap to UnExpand' : ''}', 
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 24)
                              ),
                              const TextField(),
                              const Spacer(),
                              Text(value),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                onSwipe: (dx, dy, direction, reverseAnimation, item) async {
                  if(direction== DismissDirection.down && item == "Testing1"){
                    Future.delayed(const Duration(milliseconds: 10)).then((value) {
                      reverseAnimation(2);
                    });
                  }
                  else{
                    if(direction == DismissDirection.startToEnd){
                      feedController.completeFillBar(0.75, const Duration(milliseconds: 600), IconPosition.RIGHT, CardPosition.Right);
                    }
                    else if(direction == DismissDirection.endToStart){
                      feedController.completeFillBar(0.75, const Duration(milliseconds: 600), IconPosition.LEFT, CardPosition.Left);
                    }
                    else if(direction == DismissDirection.up){
                      
                      if(dx >= 0){
                        feedController.completeFillBar(1.0, const Duration(milliseconds: 600), IconPosition.TOP, CardPosition.Right);
                      }
                      else{
                        feedController.completeFillBar(1.0, const Duration(milliseconds: 600), IconPosition.TOP, CardPosition.Left);
                      }
                    }
                    else if(direction == DismissDirection.down){
                      if(dx >= 0){
                        feedController.completeFillBar(0.75, const Duration(milliseconds: 600), IconPosition.BOTTOM, CardPosition.Right);
                      }
                      else{
                        feedController.completeFillBar(0.75, const Duration(milliseconds: 600), IconPosition.BOTTOM, CardPosition.Left);
                      }
                    }
                  }
                },
                // placeholder: Center(
                //   child: Container(
                //     decoration: BoxDecoration(
                //       color: Colors.green,
                //       borderRadius: BorderRadius.circular(16),
                //       border: Border.all(color: Colors.amber, width: 3)
                //     ),
                //   )
                // ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}