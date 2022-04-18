import 'package:flutter/material.dart';
import 'package:fort/fort.dart';

class FeedCardState {

  @override
  bool operator==(dynamic other){
    return false;
  }
}

class SwipeCardHideState extends FeedCardState{
  final Widget? overlay;
  SwipeCardHideState([this.overlay]);

  @override
  bool operator==(dynamic other){
    return other is SwipeCardHideState;
  }
}

class SwipeCardShowState extends FeedCardState{
  SwipeCardShowState();

  @override
  bool operator==(dynamic other){
    return other is SwipeCardShowState;
  }
}

class SwipeCardExpandState extends FeedCardState{
  SwipeCardExpandState();

  @override
  bool operator==(dynamic other){
    return other is SwipeCardExpandState;
  }
}
class SwipeFeedCardState extends FortState{

  final FeedCardState state;

  SwipeFeedCardState({
    required this.state
  });

  factory SwipeFeedCardState.initial([FeedCardState? cardState]) => SwipeFeedCardState(
    state: cardState ?? SwipeCardHideState()
  );

  static Tower<SwipeFeedCardState> tower([FeedCardState? cardState]){
    return Tower<SwipeFeedCardState>(
      _swipeFeedCardStateReducer,
      initialState: SwipeFeedCardState.initial(cardState)
    );
  }

  @override
  FortState copyWith(FortState other) {
    return this;
  }

  @override
  toJson() {
    
  }
}

class SwipeFeedCardEvent{}

class SetSwipeFeedCardState extends SwipeFeedCardEvent{
  FeedCardState state;
  SetSwipeFeedCardState(this.state);
}

SwipeFeedCardState _swipeFeedCardStateReducer(SwipeFeedCardState state, dynamic event){
  if(event is SwipeFeedCardEvent){
    return SwipeFeedCardState(
      state: setSwipeFeedCardStateReducer(state, event)
    );
  }
  return state;
}

FeedCardState setSwipeFeedCardStateReducer(SwipeFeedCardState state, dynamic event){
  if(event is SetSwipeFeedCardState){
    return event.state;
  }
  else{
    return state.state;
  }
}