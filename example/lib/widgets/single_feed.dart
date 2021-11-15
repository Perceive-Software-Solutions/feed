import 'package:feed/feed.dart';
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';
import 'package:sliding_sheet/sliding_sheet.dart';

class SingleFeedExample extends StatefulWidget {
  final ScrollController controller;
  final SheetController sheetController;
  const SingleFeedExample({ 
    Key? key,
    required this.controller,
    required this.sheetController
  }) : super(key: key);

  @override
  _SingleFeedExampleState createState() => _SingleFeedExampleState();
}

class _SingleFeedExampleState extends State<SingleFeedExample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: SingleFeed(
          sheetController: widget.sheetController,
          controller: widget.controller,
          headerBuilder: (context){
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
                      const Text('Single Feed', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
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
          loader: (int size, [String? token]) async {
            int index = int.parse(token ?? '0');
            return Tuple2(List.generate(size, (i) => i + index), (index + size).toString());
          },
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
                  Container(
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