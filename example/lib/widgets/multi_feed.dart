import 'package:feed/feed.dart';
import 'package:flutter/material.dart';
import 'package:perceive_slidable/sliding_sheet.dart';

@Deprecated('Deleted Multi Feed')
class MultiFeedExample extends StatefulWidget {
  final SheetController? sheetController;

  const MultiFeedExample({ 
    Key? key ,
    this.sheetController
  }) : super(key: key);

  @override
  _MultiFeedExampleState createState() => _MultiFeedExampleState();
}

class _MultiFeedExampleState extends State<MultiFeedExample> with TickerProviderStateMixin{

  FocusNode focusNode = FocusNode();

  ///Controller for the multifeed
  late MultiFeedController feedController;

  @override
  void initState() {
    super.initState();

    focusNode.addListener(() { 
      if(!focusNode.hasFocus){
        print("Hello");
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        floatingActionButton: GestureDetector(
          child: Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: Colors.blue,
            ),
          ),
          onTap: (){
            // feedController.addItem(3, 1);
          }
        ),
        body: Stack(
          children: [
            Positioned.fill(
              top: 0,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                // child: MultiFeed(
                //   controller: feedController,
                //   sheetController: widget.sheetController,
                //   headerBuilder: (context, i){
                //     return Column(
                //       children: [
                //         Padding(
                //           padding: const EdgeInsets.only(top: 32, right: 34),
                //           child: Row(
                //             crossAxisAlignment: CrossAxisAlignment.center,
                //             mainAxisAlignment: MainAxisAlignment.start,
                //             children: [
                //               IconButton(
                //                 icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
                //                 onPressed: () => Navigator.of(context).pop(),
                //               ),
                //               const Spacer(),
                //               const Text('Multi-Feed', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                //               const Spacer()
                //             ],
                //           ),
                //         ),
                //         const Padding(
                //           padding: EdgeInsets.only(top: 32, bottom: 32),
                //           child: Text('Asynchronous list that loads depending on position of list', textAlign: TextAlign.center),
                //         ),
                //       ],
                //     );
                //   },
                //   placeHolders: <Widget>[
                //     Container(
                //       height: 300,
                //       width: 300,
                //       color: Colors.blue,
                //       child: const Text("First Page", style: TextStyle(fontSize: 70, color: Colors.black,))
                //     ),
                //     Container(
                //       height: 300,
                //       width: 300,
                //       color: Colors.blue,
                //       child: const Text("First Page", style: TextStyle(fontSize: 70, color: Colors.black,))
                //     ),
                //     // Container(
                //     //   height: 300,
                //     //   width: 300,
                //     //   color: Colors.blue,
                //     //   child: const Text("First Page", style: TextStyle(fontSize: 70, color: Colors.black,))
                //     // ),
                //   ],
                //   //Loaders defined to retreive data for each index in the feed
                //   loaders: List.filled(3, (int size, [String? token]) async {
                //     int index = int.parse(token ?? '0');
                //     return Tuple2(List.generate(size, (i) => i + index), (index + size).toString());
                //   }),
                //     //item builder for each element of the feed dependant on the data from ther loaders
                //   childBuilder: (item, index, isLast) {

                //     var list = ['2', '59', '60', '61', '63', '64'];

                //     return Padding(
                //       padding: const EdgeInsets.only(left: 16, right: 16),
                //       child: Column(
                //         children: [
                //           Container(
                //             height: 1,
                //             color: Colors.grey.withOpacity(0.2),
                //           ),
                //           SizedBox(
                //             height: 75,
                //             child: Center(
                //               child: Text(list[item % 6], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))
                //             ),
                //           ),
                //         ],
                //       ),
                //     );
                //   },
                // ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Container(
                  height: 100,
                  color: Colors.white,
                  width: MediaQuery.of(context).size.width,
                  child: TextField(),
                ),
              ),
            )
          ],
        )
      ),
    );
  }
}