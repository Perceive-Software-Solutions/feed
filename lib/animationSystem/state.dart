import 'package:feed/feed.dart';
import 'package:fort/fort.dart';

class AnimationSystemState extends FortState{

  final IconPosition? iconPosition;
  final CardPosition? cardPosition;
  final double fill;

  AnimationSystemState({
    required this.fill,
    this.iconPosition,
    this.cardPosition
  });

  factory AnimationSystemState.initial() => AnimationSystemState(fill: 0);

  static Tower<AnimationSystemState> tower([AnimationSystemState? cardState]){
    return Tower<AnimationSystemState>(
      _animationSystemReducer,
      initialState: AnimationSystemState.initial()
    );
  }

  @override
  FortState copyWith(FortState other) {
    throw UnimplementedError();
  }

  @override
  toJson() {
    throw UnimplementedError();
  }
}

/*
 
   _____                 _        
  | ____|_   _____ _ __ | |_ ___  
  |  _| \ \ / / _ \ '_ \| __/ __| 
  | |___ \ V /  __/ | | | |_\__ \ 
  |_____| \_/ \___|_| |_|\__|___/ 
                                  
 
*/

class AnimationSystemEvent{}


class SetAllAnimationValues extends AnimationSystemEvent{
  double fill;
  IconPosition? iconPosition;
  CardPosition? cardPosition;
  SetAllAnimationValues(this.fill, this.iconPosition, this.cardPosition);
}

AnimationSystemState _animationSystemReducer(AnimationSystemState state, dynamic event){
  if(event is AnimationSystemEvent){
    if(event is SetAllAnimationValues){
      return AnimationSystemState(
        fill: event.fill,
        iconPosition: event.iconPosition,
        cardPosition: event.cardPosition
      );
    }
  }
  return state;
}

