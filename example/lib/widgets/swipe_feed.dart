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

  Future<Tuple2<List<dynamic>, String>> loadItems(int size, [String? token]) async {
    await Future.delayed(const Duration(seconds: 1));
    return const Tuple2(['Testing', 'Testing1', 'Testin2', 'Testing3', 'Testing4'], 'PageToken');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 32, left: 16, right: 16, bottom: 30),
        child: Column(
          children: [
            Padding(
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 32),
                child: SwipeFeed<dynamic>(
                  controller: feedController,
                  loader: loadItems,
                  swipeAlert: (index){
                    return true;
                  },
                  overlayBuilder: (forwardAnimation, reverseAnimation, index, item){
                    return Container(
                      height: 300,
                      width: 300,
                      color: Colors.black,
                      child: MaterialButton(
                        child: Text(item, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 24)),
                        onPressed: (){
                          forwardAnimation(index);
                        }
                      )
                    );
                  },
                  childBuilder: (value, isLast) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16)
                      ),
                      child: Center(
                        child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 24)),
                      ),
                    );
                  },
                  onSwipe: (dx, dy, direction, item) async{
                    if(direction == DismissDirection.startToEnd){
                      feedController.completeFillBar(0.75, IconPosition.RIGHT, CardPosition.Right);
                    }
                    else if(direction == DismissDirection.endToStart){
                      feedController.completeFillBar(0.75, IconPosition.LEFT, CardPosition.Left);
                    }
                    else if(direction == DismissDirection.up){
                      if(dx >= 0){
                        feedController.completeFillBar(0.75, IconPosition.TOP, CardPosition.Right);
                      }
                      else{
                        feedController.completeFillBar(0.75, IconPosition.TOP, CardPosition.Left);
                      }
                    }
                    else if(direction == DismissDirection.down){
                      if(dx >= 0){
                        feedController.completeFillBar(1.0, IconPosition.BOTTOM, CardPosition.Right);
                      }
                      else{
                        feedController.completeFillBar(1.0, IconPosition.BOTTOM, CardPosition.Left);
                      }
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}