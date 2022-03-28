
part of 'perceive_slidable.dart';

/*
 
   ____  _        _       
  / ___|| |_ __ _| |_ ___ 
  \___ \| __/ _` | __/ _ \
   ___) | || (_| | ||  __/
  |____/ \__\__,_|\__\___|
                          
 
*/

class PerceiveSlidableState extends FortState<PerceiveSlidableState>{

  final double extent;

  final double statusBarHeight;

  final List<PerceiveSlidableDelegate> delegates;

  PerceiveSlidableState({
    required this.statusBarHeight, 
    required this.delegates,
    required this.extent,
  });

  factory PerceiveSlidableState.initial(double statusBarHeight, PerceiveSlidableDelegate initial, double extent) => PerceiveSlidableState(
    statusBarHeight: statusBarHeight, 
    delegates: [initial],
    extent: extent
  );

  static Tower<PerceiveSlidableState> tower({required double statusBarHeight, required PerceiveSlidableDelegate initialDelegate, required double initialExtent}) => Tower<PerceiveSlidableState>(
    _reducer,
    initialState: PerceiveSlidableState.initial(statusBarHeight, initialDelegate, initialExtent)
  );

  @override
  FortState<PerceiveSlidableState> copyWith(FortState<PerceiveSlidableState> other) {
    // TODO: implement copyWith
    throw UnimplementedError();
  }

  @override
  toJson() {
    // TODO: implement toJson
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

abstract class _SlidableEvent{}

class _SetExtentEvent extends _SlidableEvent{
  final double extent;

  _SetExtentEvent(this.extent);
}

class _AddDelegateEvent extends _SlidableEvent{
  final PerceiveSlidableDelegate delegate;

  _AddDelegateEvent(this.delegate);
}

class _RemoveLastDelegateEvent extends _SlidableEvent{}

/*
 
   ____          _                     
  |  _ \ ___  __| |_   _  ___ ___ _ __ 
  | |_) / _ \/ _` | | | |/ __/ _ \ '__|
  |  _ <  __/ (_| | |_| | (_|  __/ |   
  |_| \_\___|\__,_|\__,_|\___\___|_|   
                                       
 
*/

PerceiveSlidableState _reducer(PerceiveSlidableState state, dynamic event){
  if(event is _SlidableEvent){
    return PerceiveSlidableState(
      statusBarHeight: state.statusBarHeight,
      extent: event is _SetExtentEvent ? event.extent : state.extent,
      delegates: _delegateReducer(state, event)
    );
  }
  return state;
}

List<PerceiveSlidableDelegate> _delegateReducer(PerceiveSlidableState state, _SlidableEvent event){
  final list = [...state.delegates];
  if(event is _RemoveLastDelegateEvent){
    //remove last item in the delegates list
    list.removeLast();
  }
  else if(event is _AddDelegateEvent){
    list.add(event.delegate);
  }
  return list;
}