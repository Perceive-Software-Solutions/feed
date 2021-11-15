import 'package:example/widgets/single_feed.dart';
import 'package:flutter/material.dart';
import 'package:sliding_sheet/sliding_sheet.dart';

class SlidingSheetExample extends StatefulWidget {
  const SlidingSheetExample({ Key? key }) : super(key: key);

  @override
  _SlidingSheetExampleState createState() => _SlidingSheetExampleState();
}

class _SlidingSheetExampleState extends State<SlidingSheetExample> {

  late SheetController sheetController;

  double extent = 0.7;

  bool snapping = false;

  @override
  void initState(){
    sheetController = SheetController();
  }

  void sheetStateListener(SheetState state){
    
    if(state.extent == 0.0){
      Navigator.pop(context);
    }
    extent = state.extent;
  }

  @override
  Widget build(BuildContext context) {
    return SlidingSheet(
      controller: sheetController,
      color: Colors.transparent,
      closeOnBackButtonPressed: true,
      closeOnBackdropTap: true, //Closes the page when the sheet reaches the bottom
      extendBody: true,
      cornerRadius: 32,
      cornerRadiusOnFullscreen: 0,
      duration: const Duration(milliseconds: 300),
      snapSpec: const SnapSpec(
        initialSnap: 0.7,
        snappings: [0.0, 0.7, 1.0],
      ),
      listener: sheetStateListener,
      headerBuilder: (context, sheet){
        return const SizedBox(
          height: 100,
        );
      },
      customBuilder: (context, controller, sheet){
        return SingleFeedExample(controller: controller, sheetController: sheetController,);
      },
    );
  }
}