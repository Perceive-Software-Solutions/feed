import 'package:feed/feed.dart';
import 'package:flutter/material.dart';
import 'package:feed/feeds/multi_feed.dart';
import 'package:tuple/tuple.dart';
import 'package:sliding_sheet/sliding_sheet.dart';


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

  ///Controller for the multifeed
  late MultiFeedController feedController;

  @override
  void initState() {
    super.initState();

    //Initialize the feed controller
    feedController = MultiFeedController(
      pageCount: 3,
      initialPage: 1,
      keepPage: true,
      vsync: this
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: MultiFeed(
          controller: feedController,
          sheetController: widget.sheetController,
          headerBuilder: (context, i){
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 32, right: 34),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      const Text('Multi-Feed', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                      const Spacer()
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 32, bottom: 32),
                  child: Text('Asynchronous list that loads depending on position of list', textAlign: TextAlign.center),
                ),
              ],
            );
          },
          //Loaders defined to retreive data for each index in the feed
          loaders: List.filled(3, (int size, [String? token]) async {
            int index = int.parse(token ?? '0');
            return Tuple2(List.generate(size, (i) => i + index), (index + size).toString());
          }),
            //item builder for each element of the feed dependant on the data from ther loaders
          childBuilder: (item, isLast) {

            var list = ['2', '59', '60', '61', '63', '64'];

            return Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: Column(
                children: [
                  Container(
                    height: 1,
                    color: Colors.grey.withOpacity(0.2),
                  ),
                  SizedBox(
                    height: 75,
                    child: Center(
                      child: Text(list[item % 6], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      )
    );
  }
}