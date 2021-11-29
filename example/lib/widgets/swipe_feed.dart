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
    await Future.delayed(const Duration(seconds: 5));
    return const Tuple2(['Testing', 'Testing1', 'Testin2', 'Testing3', 'Testing4', 'Testing5', 'Testing6', 'Testing7', 'Testing8', 'Testing9'], 'PageToken');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        floatingActionButton: GestureDetector(
          child: Container(
            height: 40,
            width: 40,
            child: const Icon(Icons.plus_one, size: 20),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(40)
            ),
          ),
          onTap: (){
            feedController.swipeRight();
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
              child: SwipeFeed<dynamic>(
                padding: const EdgeInsets.only(top: 57 + 16, left: 8, right: 8, bottom: 49 + 13),
                duration: const Duration(milliseconds: 300),
                controller: feedController,
                loader: loadItems,
                swipeAlert: (index){
                  return false;
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
                childBuilder: (dynamic value, bool isLast, bool isExpanded, void Function() close ) {
                  return Container(
                    decoration: BoxDecoration(
                      color: isExpanded ? Colors.red : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black, width: 3)
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
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                onSwipe: (dx, dy, direction, item) async {
                  if(direction == DismissDirection.startToEnd){
                    feedController.completeFillBar(0.75, const Duration(milliseconds: 800), IconPosition.RIGHT, CardPosition.Right);
                  }
                  else if(direction == DismissDirection.endToStart){
                    feedController.completeFillBar(0.75, const Duration(milliseconds: 800), IconPosition.LEFT, CardPosition.Left);
                  }
                  else if(direction == DismissDirection.up){
                    if(dx >= 0){
                      feedController.completeFillBar(1.0, const Duration(milliseconds: 800), IconPosition.TOP, CardPosition.Right);
                    }
                    else{
                      feedController.completeFillBar(1.0, const Duration(milliseconds: 800), IconPosition.TOP, CardPosition.Left);
                    }
                  }
                  else if(direction == DismissDirection.down){
                    if(dx >= 0){
                      feedController.completeFillBar(0.75, const Duration(milliseconds: 800), IconPosition.BOTTOM, CardPosition.Right);
                    }
                    else{
                      feedController.completeFillBar(0.75, const Duration(milliseconds: 800), IconPosition.BOTTOM, CardPosition.Left);
                    }
                  }
                },
                placeholder: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber, width: 3)
                    ),
                  )
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}