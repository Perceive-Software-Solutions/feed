import 'dart:ui';

import 'package:example/widgets/multi_feed.dart';
import 'package:feed/feed.dart';
import 'package:feed/feeds/sliding_sheet_feed.dart';
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';
import 'package:perceive_slidable/sliding_sheet.dart';

class SlidingFeedExample extends StatefulWidget {
  const SlidingFeedExample({ Key? key }) : super(key: key);

  @override
  _SlidingFeedExampleState createState() => _SlidingFeedExampleState();
}

class _SlidingFeedExampleState extends State<SlidingFeedExample> with TickerProviderStateMixin{

  //  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ State ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///Controller for the slidingSheet
  late SlidingSheetFeedController sheetController;

  @override
  void initState(){
    super.initState();
    sheetController = SlidingSheetFeedController(
      pageCount: 3,
      initialPage: 1,
      keepPage: true,
      vsync: this,
      gridDelegateGenerator: (index) {
        if(index != 1) {
          return null;
        }
        return FeedGridViewDelegate(padding: const EdgeInsets.all(8));
      },
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

  Widget headerBuilder(Widget child){
    return Container(
      color: Colors.yellow[100],
      // height: 10,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            child,

            Container(
              height: 50,
              // alignment: Alignment.bottomCenter,
              
            )
          ],
        ),
      ),
    );
  }

  Widget childBuilder(dynamic item, int index){
    var list = ['2', '59', '60', '61', '63', '64'];
    bool isGrid = sheetController.multifeedController.isGridIndex(index);
    return Padding(
      padding: EdgeInsets.all( isGrid ? 0 : 8),
      child: Container(
        height: lerpDouble(75, 275, (item % 6) / 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32)
        ),
        child: Center(
          child: Text(list[item % 6], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))
        ),
      ),
    );
  }

  Widget wrapper(BuildContext context, Widget child, int index) {

    Widget list = sheetController.multifeedController.list(index).isEmpty ? const SizedBox(height: 700, width: double.infinity,) : child;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 20.0),
            child: Center(child: Text('Wrapper')),
          ),

          Container(
            child: list,
            decoration: BoxDecoration(
              color: Colors.red[200],
              borderRadius: BorderRadius.circular(32)
            ),
          ),
        ],
      ),
    );
  }

  Widget placeholder(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.only(bottom: 20.0),
        child: Center(child: Text('PlaceHolder')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlidingSheetFeed(
      //Controllers
      controller: sheetController,
      //Params
      color: Colors.white,
      staticSheet: true,
      closeOnBackButtonPressed: true,
      closeOnBackdropTap: true, //Closes the page when the sheet reaches the bottom
      extendBody: true,
      cornerRadius: 32,
      cornerRadiusOnFullscreen: 0,
      duration: const Duration(milliseconds: 300),
      //Loaders
      loaders: List.filled(3, (int size, [String? token]) async {
        int index = int.parse(token ?? '0');
        await Future.delayed(const Duration(seconds: 3));
        return Tuple2(List.generate(size, (i) => i + index), null);
      }),
      // header: (context, i, child){
      //   return headerBuilder();
      // },
      // footer: (context, _){
      //   return SafeArea(
      //     bottom: true,
      //     child: Container(
      //       height: 83,
      //       width: MediaQuery.of(context).size.width,
      //       color: Colors.blue[100],
      //       child: Padding(
      //         padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      //         child: TextField()
      //       )
      //     ),
      //   );
      // },
      //Builders
      header: (context, _, child){
        return headerBuilder(child);
      },
      childBuilder: (item, index, isLast) {
        return GestureDetector(
          onTap: (){
            sheetController.push(MultiFeedExample(sheetController: sheetController.sheetController));
          },
          child: childBuilder(item, index)
        );
      },
      placeHolders: (extet, height){
        return [
          placeholder(context),
          placeholder(context),
          placeholder(context),
        ];
      },
      
      //Widgets
      wrapper: wrapper,
    );
  }
}