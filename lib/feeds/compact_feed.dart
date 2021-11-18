import 'package:feed/providers/color_provider.dart';
import 'package:feed/widgets/horizontal_bar.dart';
import 'package:feed/widgets/neumorpic_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

typedef PagedCompactListLoader<T> = Future<List<T>> Function(int size);
typedef PagedCompactListBuilder<T> = Widget Function(BuildContext context, int index, T item);

///[PagedCompactList] is a lazy loading list with a Load More button.
///
///The widget handles the state management for the list items. 
///The innitial items are loaded in automatincally, however, 
///The [PagedCompactListController] and the [loader] are used to manage the adding of additional items.
///
///the [Builder] allows for complete control over the display of those items. 
///
///The widget has an [INITIAL_PAGE_SIZE] for showing a minimal set items, 
///and a [PAGE_SIZE] that determines the amount of items being added.
///
///A [title] is displayed above the list.
class PagedCompactList<T> extends StatefulWidget {

  const PagedCompactList({
    Key? key, 
    required this.loader, 
    required this.builder, 
    required this.child,
    this.loadSize = PAGE_SIZE, 
    this.controller, 
    this.title
  }) 
  : assert(loadSize > 0),
    super(key: key);

  ///Default for [loadSize]
  static const int PAGE_SIZE = 15;

  ///The loader is a function that uses the the next size of the list 
  ///to provide a way for the widget to load items into its state.
  ///
  ///Called when the Load More button is pressed, and 
  ///the size provided will increase according to the [loadSize].
  ///
  ///The `output` must be all items of the list. 
  ///If the `output.length < size` then the Load More button is removed.
  final PagedCompactListLoader<T> loader;

  ///Item builder used to display indexed items
  final PagedCompactListBuilder<T> builder;

  ///Used by the [loader] to increment the `items` list. 
  final int loadSize;

  ///Controller for the [PagedCompactList]. 
  final PagedCompactListController<T>? controller;

  ///Title of the list. 
  ///Does not build if not defined.
  final String? title;

  ///Load more child
  ///Button
  final Widget child;

  @override
  _PagedCompactListState<T> createState() => _PagedCompactListState<T>();
}

class _PagedCompactListState<T> extends State<PagedCompactList<T>> {

  ///The size of the innitial compacted page. 
  ///When it is reset, it reverts to the [INITIAL_PAGE_SIZE]
  final int INITIAL_PAGE_SIZE = 3;

  ///The base animation duration 
  ///for adding and removing items.
  final Duration _animationDuration = Duration(milliseconds: 0);

  ///State for list items
  List<T> items = [];

  ///When toggled, removes the Load More button used to invoke the [loader]
  ///
  ///Determines if the full list is loaded in. 
  ///Toggled when the [loader] returns less items than the requested amount. 
  bool maxCapacity = false;

  ///Toggled when the paged list is retreiving items. 
  ///Untoggled when the the fetch is complete
  bool loading = false;

  ///Key for accessing the [AnimatedListState]
  ///Used to animate the adding/removing of items to the [items] list 
  final GlobalKey<AnimatedListState> animatedListKey = GlobalKey<AnimatedListState>();

  ///Calculates the next size for the [PagedCompactList]. 
  int get nextSize{
    
    ///If the `[items].length >= [INITIAL_PAGE_SIZE]`
    ///then this returns the the next size relative to [widget.loadSize].
    if(items.length >= INITIAL_PAGE_SIZE){
      return items.length + widget.loadSize;
    }

    ///Otherwise returns [INITIAL_PAGE_SIZE]
    else{
      return INITIAL_PAGE_SIZE;
    }
  }

  ///The current size of the [items] list
  int get size => items.length;

  ///Determines if the [PagedCompactList] is in loading mode. 
  ///This occurs if there are new items loading, or no items loaded.
  bool get isLoading => loading || items.isEmpty;

  ///Returns the [AnimatedListState] refrenced within the [animatedListKey]
  AnimatedListState get animationState => animatedListKey.currentState!;

  @override
  void initState() {
    super.initState();

    ///Resets the page when the [animationState] is connected
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      reset();
    });
  }

  @override
  void didChangeDependencies(){
    super.didChangeDependencies();

    //Bind the controller
    widget.controller?._bind(this);
  }
  
  ///When invoked deletes an indexed item from the list. 
  ///An animation is invoked when the item is removed. 
  void remove(int index){

    //Ensures that index is not out of bounds
    assert(index < items.length);

    //Remove the item from the list. 
    //Store so that is can be provided to the builder
    T removed = items.removeAt(index);

    //Animate the removal of the item from the list. 
    //Provides the removed item after its been removed from state
    animationState.removeItem(
      index, 
      (context, animation) => _builder(context, index, removed, animation),
      duration: _animationDuration
    );
  }
  
  ///Resets the [items] list. 
  ///If the list of empty, calls the loader with [INITIAL_PAGE_SIZE]
  void reset(){

    ///untoggles [maxCapacity].
    setState(() {
      maxCapacity = false;
    });

    ///If there are more items than the [INITIAL_PAGE_SIZE]
    if(items.length > INITIAL_PAGE_SIZE){
      ///Removes items from the [items] list until [INITIAL_PAGE_SIZE]
      for (var i = items.length - 1; i >= INITIAL_PAGE_SIZE; i--) {
        remove(i);
      }
    }
    else if(items.length < INITIAL_PAGE_SIZE){
      ///If there are less items than the [INITIAL_PAGE_SIZE]
      ///load the innitial page.
      fetchPage(INITIAL_PAGE_SIZE);
    }
    
    
  }

  ///Retreives the new list of items by invoking the [widget.loader]. 
  ///Updates the list of items and animates thier insertion to the list. 
  Future<void> fetchPage(int size) async {
    
    //Loading toggled
    setState(() {
      loading = true;
    });

    //Retreives items from the loader
    List<T> loadedItems = await widget.loader(size);

    //Retrives the amount of new items
    int addedLength = loadedItems.length - items.length;
    assert(addedLength >= 0);

    ///If the `loadedItems.length < size` 
    ///then the [maxCapacity] is toggled.
    ///[loading] is also untoggled
    setState(() {
      if(loadedItems.length < size){
        maxCapacity = true;
      }
      loading = false;
    });

    //Set the items list
    items = loadedItems;

    //Animates adding the items to the list
    for (var i = loadedItems.length - addedLength; i < loadedItems.length; i++) {
      animationState.insertItem(i, duration: _animationDuration);
    }
  }


  @override
  Widget build(BuildContext context) {

    //Color provider
    final appColors = ColorProvider.of(context);

    //Text style provider
    final textStyles = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          //Displays title. 
          //Only displays when the title variable is defined 
          if(widget.title?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0, left: 16),
              child: Text(widget.title!, style: textStyles.headline5!.copyWith(color: appColors.onBackground),),
            ),

          NeumorpicCard(
            color: appColors.surface,
            borderRadius: BorderRadius.circular(32),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 500),
              child: Column(
                children: [

                  ///Primary animated list. 
                  ///Manages the state of animating and displaying the [items]
                  AnimatedList(
                    physics: NeverScrollableScrollPhysics(),
                    key: animatedListKey,
                    shrinkWrap: true,
                    initialItemCount: 0,
                    itemBuilder: (context, index, animation) {
                      return _builder(context, index, items[index], animation);
                    },
                  ),
                  
                  ///Only displays if [maxCapacity] is toggled off
                  if(!maxCapacity)
                    GestureDetector(
                      onTap: () => isLoading ? fetchPage(nextSize) : null,
                      child: widget.child,
                    )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  ///Builds a child within the list, animating its addition and removal. 
  ///
  ///Child building is offloaded to the [widget.builder] function 
  Widget _builder(BuildContext context, int index, T item, Animation<double> animation){

    //Color provider
    final appColors = ColorProvider.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(1, 0),
              end: Offset.zero
            ).animate(animation),
            child: widget.builder(context, index, item)
          ),
        ),

        //Horizontal Bar
        if(index < items.length - 1)
          Padding(
            padding: const EdgeInsets.only(left: 77.0),
            child: HorizontalBar(
              width: 0.5,
              color: appColors.grey!.withOpacity(0.25),
            ),
          ),
      ],
    );
  }
}

///Used to control the internal state of the [PagedCompactList]. 
///The controller can be used to reset and add to the list. 
///Can also be used to retrive state information.
class PagedCompactListController<T> extends ChangeNotifier{

  late _PagedCompactListState<T>? _state;

  ///Binds the controller
  void _bind(_PagedCompactListState<T> bind) => _state = bind;

  ///Removes an indexed item from the list
  void remove(int index) => _validate((state) => state.remove(index));

  // Checks if the compact list is currently loading
  bool get isLoading => _state!.loading || _state!.items.isEmpty;

  ///Remove a specific typed item from the list, 
  ///Only if it exists
  void removeItem(T item){
    _validate((state){
      //find index
      int index = state.items.indexOf(item);

      if(index >= 0){
        //remove item
        state.remove(index);
      }
    });
  }

  ///Resets the list of items to the [INITIAL_PAGE_STATE]
  void reset() => _validate((state) => state.reset());

  ///Loads a defined amount of items to the list
  void load(int size) => _validate((state) => state.fetchPage(size));

  ///Returns the current size of the list
  int get size => _validate((state) => state.size);

  ///Retruns the nextSize of the list
  int get nextSize => _validate((state) => state.nextSize);

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
    super.dispose();
  }

  ///Provider for validated [_PagedCompactListState]. 
  ///Throws an error if it is not bound
  T _validate<T>(T Function(_PagedCompactListState state) validated){
    if(_state == null){
      throw('_PagedCompactListState not bound');
    }

    //provides state
    return validated(_state!);
  }

}