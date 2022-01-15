import 'package:feed/feed.dart';
import 'package:feed/swipeCard/swipe_card.dart';
import 'package:flutter/material.dart';
import 'package:fort/fort.dart';

class SwipeFeedCard extends StatefulWidget {

  final SwipeFeedCardController controller;
  final Store<SwipeFeedCardState> store;
  final Function(double dx, double dy, [double? maxX, double? maxYTop, double? maxYBot])? onPanUpdate;
  final void Function(double dx, double dy, Future<void> Function(int), DismissDirection direction)? onSwipe;

  const SwipeFeedCard({ 
    Key? key,
    required this.controller,
    required this.store,
    this.onPanUpdate,
    this.onSwipe
  }) : super(key: key);

  @override
  _SwipeFeedCardState createState() => _SwipeFeedCardState();
}

class _SwipeFeedCardState extends State<SwipeFeedCard> {

  late SwipeCardController swipeCardController;

  @override
  void initState(){
    swipeCardController = SwipeCardController();
  }

  dynamic _onSwipe(double dx, double dy, DismissDirection direction){

  }




  @override
  Widget build(BuildContext context) {
    return SwipeCard(
      controller: swipeCardController,  
      swipable: true,
      opacityChange: true,
      onPanUpdate: widget.onPanUpdate != null ? widget.onPanUpdate : null,
      onSwipe: _onSwipe,
    );
  }
}

///Controller for the swipe card
class SwipeFeedCardController extends ChangeNotifier {

  late _SwipeFeedCardState? _state;

  SwipeFeedCardController();

  void _bind(_SwipeFeedCardState bind) => _state = bind;

  /// Forward Animation
  

  /// Reverse Animation

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
    super.dispose();
  }
}

