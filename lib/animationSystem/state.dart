import 'package:feed/feed.dart';
import 'package:fort/fort.dart';

class AnimationSystemState extends FortState{

  final IconPosition? iconPosition;
  final CardPosition? cardPosition;
  final bool nullFill;

  AnimationSystemState({
    this.iconPosition,
    this.cardPosition,
    this.nullFill = false
  });

  factory AnimationSystemState.initial() => AnimationSystemState();

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
  IconPosition? iconPosition;
  CardPosition? cardPosition;
  bool nullFill;
  SetAllAnimationValues(this.iconPosition, this.cardPosition, {this.nullFill = false});
}

AnimationSystemState _animationSystemReducer(AnimationSystemState state, dynamic event){
  if(event is AnimationSystemEvent){
    if(event is SetAllAnimationValues){
      return AnimationSystemState(
        iconPosition: event.iconPosition,
        cardPosition: event.cardPosition,
        nullFill: event.nullFill
      );
    }
  }
  return state;
}

