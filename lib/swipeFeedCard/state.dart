import 'package:fort/fort.dart';

enum FeedCardState{
  SwipeCardHideState,
  SwipeCardShowState,
  SwipeCardExpandState,
}

class SwipeFeedCardState extends FortState{

  final FeedCardState state;

  SwipeFeedCardState({
    required this.state
  });

  factory SwipeFeedCardState.initial() => SwipeFeedCardState(
    state: FeedCardState.SwipeCardHideState
  );

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

SwipeFeedCardState swipeFeedCardStateReducer(SwipeFeedCardState state, dynamic event){
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