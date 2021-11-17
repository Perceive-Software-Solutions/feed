import 'package:example/widgets/multi_feed.dart';
import 'package:feed/feed.dart';
import 'package:flutter/material.dart';
import 'package:sliding_sheet/sliding_sheet.dart';
import 'package:tuple/tuple.dart';

class SlidingFeedExample extends StatefulWidget {
  const SlidingFeedExample({ Key? key }) : super(key: key);

  @override
  _SlidingFeedExampleState createState() => _SlidingFeedExampleState();
}

class _SlidingFeedExampleState extends State<SlidingFeedExample> with TickerProviderStateMixin{

  //  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ State ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///Controller for the slidingSheet
  late SheetController sheetController;

  ///Controller for the multifeed
  late SimpleMultiFeedController feedController;

  @override
  void initState(){
    super.initState();
    sheetController = SheetController();

    //Initialize the feed controller
    feedController = SimpleMultiFeedController(
      pageCount: 3,
      initialPage: 1,
      keepPage: true,
      vsync: this
    );
  }

  void sheetStateListener(SheetState state){

    if(state.extent == 0.0){
      if(Navigator.canPop(context)){
        Navigator.pop(context);
      }
    }
  }

  //  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Helpers ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Widget headerBuilder(){
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 30),
      child: Column(
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
      ),
    );
  }

  Widget childBuilder(dynamic item){
    var list = ['2', '59', '60', '61', '63', '64'];
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Column(
        children: [
          Container(
            height: 1,
            color: Colors.white,
          ),
          Container(
            color: Colors.white,
            height: 75,
            child: Center(
              child: Text(list[item % 6], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlidingSheetFeed(
      //Controllers
      sheetController: sheetController,
      controller: feedController,
      //Params
      color: Colors.white,
      closeOnBackButtonPressed: true,
      closeOnBackdropTap: true, //Closes the page when the sheet reaches the bottom
      extendBody: true,
      cornerRadius: 32,
      cornerRadiusOnFullscreen: 0,
      duration: const Duration(milliseconds: 300),
      //Loaders
      loaders: List.filled(3, (int size, [String? token]) async {
        int index = int.parse(token ?? '0');
        return Tuple2(List.generate(size, (i) => i + index), (index + size).toString());
      }),
      //Builders
      headerBuilder: (context, i){
        return headerBuilder();
      },
      childBuilder: (item, isLast) {
        return childBuilder(item);
      },
      //Widgets
      page: MultiFeedExample(sheetController: sheetController),
    );
  }
}