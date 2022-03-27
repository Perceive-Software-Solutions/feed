import 'dart:math';

import 'package:feed/swipeFeed/swipe_feed.dart';
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
    return const Tuple2([], null);
  }

  @override
  Widget build(BuildContext context) {

    var height = MediaQuery.of(context).size.height;

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
            feedController.addCard('It Worked !!!!!!');
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
                padding: const EdgeInsets.only(left: 8, right: 8, top: 60, bottom: 40),
                controller: feedController,
                loader: loadItems,
                objectKey: (item){
                  return item.hashCode.toString();
                },
                canExpand: (item){
                  return true;
                },
                loadingPlaceHolder: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                  child: const Center(child: Text("Loading",style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold))),
                ),
                noItemsPlaceHolder: GestureDetector(
                  child: Container(
                    color: Colors.transparent,
                    child: const Center(child: Text("NO NEW ITEMS", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold))),
                  ),
                  onTap: (){
                    feedController.refresh();
                  },
                ),
                noConnectivityPlaceHolder: GestureDetector(
                  child: Container(
                    color: Colors.transparent,
                    child: const Center(child: Text("NO NEW ITEMS", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold))),
                  ),
                  onTap: (){
                    feedController.refresh();
                  },
                ),
                background: (context, child){
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black, width: 3),
                    ),
                    child: child,
                  );
                },
                mask: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                ),
                childBuilder: (dynamic value, bool isExpanded, void Function() close ) {
                  return Opacity(
                    opacity: 0.5,
                    child: Container(
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
                    ),
                  );
                },
                onSwipe: (dx, dy, direction, reverseAnimation, item) async {
                  return true;
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