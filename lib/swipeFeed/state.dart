import 'package:feed/swipeFeedCard/state.dart';
import 'package:fort/fort.dart';
import 'package:tuple/tuple.dart';

class SwipeFeedState<T> extends FortState<T>{

  List<Tuple2<T?, Store<SwipeFeedCardState>>> items;
  List<T>? previousPolls;
  String? pageToken;

  static const int LENGTH_INCREASE_FACTOR = 10;
  static const int LOAD_MORE_LIMIT = 3;

  SwipeFeedState({
    required this.items,
    this.previousPolls,
    this.pageToken,
  });

  @override
  FortState<T> copyWith(FortState<T> other) {
    return this;
  }

  @override
  toJson() {}
}

/*
 
   _____                 _        
  | ____|_   _____ _ __ | |_ ___  
  |  _| \ \ / / _ \ '_ \| __/ __| 
  | |___ \ V /  __/ | | | |_\__ \ 
  |_____| \_/ \___|_| |_|\__|___/ 
                                  
 
*/

class SwipeFeedEvent{}

class _SetItemsEvent extends SwipeFeedEvent{
  List<Tuple2<dynamic, Store<SwipeFeedCardState>>> items;
  _SetItemsEvent(this.items);
}

class _SetPageTokenEvent extends SwipeFeedEvent{
  String? pageToken;
  _SetPageTokenEvent(this.pageToken);
}

class _SetPreviousPollsEvent extends SwipeFeedEvent{
  List<dynamic>? items;
  _SetPreviousPollsEvent(this.items);
}

/*
 
   ____          _                      
  |  _ \ ___  __| |_   _  ___ ___ _ __  
  | |_) / _ \/ _` | | | |/ __/ _ \ '__| 
  |  _ <  __/ (_| | |_| | (_|  __/ |    
  |_| \_\___|\__,_|\__,_|\___\___|_|    
                                        
 
*/

SwipeFeedState swipeFeedStateReducer(SwipeFeedState state, dynamic event){
  if(event is SwipeFeedEvent){
    return SwipeFeedState(
      items: setItemsReducer(state, event),
      pageToken: setPageTokenReducer(state, event),
      previousPolls: setPreviousPollsReducer(state, event)
    );
  }
  return state;
}

List<Tuple2<dynamic, Store<SwipeFeedCardState>>> setItemsReducer(SwipeFeedState state, dynamic event){
  if(event is _SetItemsEvent){
    return event.items;
  }
  return state.items;
}

String? setPageTokenReducer(SwipeFeedState state, dynamic event){
  if(event is _SetPageTokenEvent){
    return event.pageToken;
  }
  return state.pageToken;
}

List<dynamic>? setPreviousPollsReducer(SwipeFeedState state, dynamic event){
  if(event is _SetPreviousPollsEvent){
    return event.items;
  }
  return state.previousPolls;
}







/*
 
      _        _   _                 
     / \   ___| |_(_) ___  _ __  ___ 
    / _ \ / __| __| |/ _ \| '_ \/ __|
   / ___ \ (__| |_| | (_) | | | \__ \
  /_/   \_\___|\__|_|\___/|_| |_|___/
                                     
 
*/

/// Removes a card from the list
void removeItem(Store<SwipeFeedState> store){
  List<Tuple2<dynamic, Store<SwipeFeedCardState>>> list = store.state.items;
  if(list.length >= 2){
    if(list[1].item1 != null){
      list[1].item2.dispatch(SetSwipeFeedCardState(FeedCardState.SwipeCardShowState));
    }
  }
}


