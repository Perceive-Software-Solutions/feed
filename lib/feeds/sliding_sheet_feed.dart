import 'package:feed/feed.dart';
import 'package:feed/util/global/functions.dart';
import 'package:flutter/material.dart';
import 'package:sliding_sheet/sliding_sheet.dart';

/// Uses package [SlidingSheet] and widget [MultiFeed]
/// Creates a multi feed that can manage its own context and list inside of a bottom modal sheet
/// *** The sliding of the list relative to the sliding sheet can not currently be 
class SlidingSheetFeed extends StatefulWidget {

  /// Cintroller for the sheet and the multi feed within
  final SlidingSheetFeedController controller;

  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Sliding Sheet ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  /// Corner radius when it is not fully expanded
  /// Default 32.0
  final double cornerRadius;

  /// Corner radius when it is fully expanded
  /// Default 0.0
  final double cornerRadiusOnFullscreen;

  /// Duration of the sliding sheet animation when sliding sheet
  /// is first instantiated
  /// Default Duration(miliseconds: 300)
  final Duration duration;

  /// Close the sheet on back button pressed
  /// Default true
  final bool closeOnBackButtonPressed;

  /// Close when the background tapped
  /// Default true
  final bool closeOnBackdropTap;

  /// If the sheet can be expanded
  /// Default true
  final bool extendBody;

  /// Background color behind the sheet
  /// Default Colors.transparent
  final Color color;

  /// Min extent of the sliding sheet
  /// Default 0.0
  final double minExtent;

  /// Initial extent of the sliding sheet
  /// Default 0.7
  final double initialExtent;

  /// Expanded extent of the sliding sheet
  /// Default 1.0
  final double expandedExtent;

  /// Header of the sheet
  final Widget header;

  /// Footer of the sheet
  final Widget footer;

  /// Disables scrolling the sheet
  final bool disableSheetScroll;

  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Multi-Feed ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  /// Loader for the feed
  final List<FeedLoader> loaders;

  /// Sliver header of the feed
  final List<Widget>? headerSliver;

  /// Sliver footer of the feed
  final List<Widget>? footerSliver;

  /// Length of items loaded
  final int? lengthFactor;

  /// Initial length of items loaded
  final int? innitalLength;

  /// Refresh function
  final Future Function()? onRefresh;

  /// Children builder
  final List<MultiFeedBuilder>? childBuilders;

  /// Child builder
  final MultiFeedBuilder? childBuilder;

  ///defines the height to offset the body
  final double? footerHeight;

  ///Disables the scroll controller when set to true
  final bool? disableScroll;

  /// Condition to hidefeed
  final bool? condition;

  /// Loading state placeholders
  final List<Widget>? placeHolders;

  /// Loading widget
  final Widget? loading;

  /// Corresponds to the [condition] and replaces feed with [Widget]
  final Widget? placeHolder;

  ///The header builder that prints over each multi feed
  final Widget Function(BuildContext context, int feedIndex)? headerBuilder;

  ///The optional function used to wrap the list view
  final IndexWidgetWrapper? wrapper;

  //  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Extra ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  const SlidingSheetFeed({ 
    Key? key,
    required this.loaders,
    required this.controller,
    this.minExtent = 0.0,
    this.initialExtent = 0.7,
    this.expandedExtent = 1.0,
    this.cornerRadius = 32.0,
    this.cornerRadiusOnFullscreen = 0.0,
    this.duration = const Duration(milliseconds: 300),
    this.closeOnBackButtonPressed = true,
    this.closeOnBackdropTap = true,
    this.extendBody = true,
    this.color = Colors.transparent,
    this.header = const SizedBox.shrink(),
    this.footer = const SizedBox.shrink(),
    this.disableSheetScroll = false,
    this.headerSliver,
    this.lengthFactor,
    this.innitalLength,
    this.onRefresh,
    this.footerSliver,
    this.childBuilders,
    this.childBuilder,
    this.footerHeight,
    this.placeHolders,
    this.placeHolder,
    this.loading,
    this.condition = false, 
    this.disableScroll, 
    this.headerBuilder,
    this.wrapper,
  }) : super(key: key);

  @override
  _SlidingSheetFeedState createState() => _SlidingSheetFeedState();
}

class _SlidingSheetFeedState extends State<SlidingSheetFeed> {

  GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    widget.controller._bind(this);
  }

  void sheetStateListener(SheetState state){
    if(state.extent == 0.0){
      if(Navigator.canPop(context)){
        Navigator.pop(context);
      }
    }
  }

  Future<dynamic> pushPage(Widget page) {
    return key.currentState!.push(MaterialPageRoute(builder: (context) => page,));
  }

  @override
  Widget build(BuildContext context) {
    return SlidingSheet(
      controller: widget.controller.sheetController,
      color: widget.color,
      closeOnBackButtonPressed: widget.closeOnBackButtonPressed,
      closeOnBackdropTap: widget.closeOnBackdropTap, //Closes the page when the sheet reaches the bottom
      extendBody: widget.extendBody,
      cornerRadius: widget.cornerRadius,
      cornerRadiusOnFullscreen: widget.cornerRadiusOnFullscreen,
      duration: widget.duration,
      snapSpec: SnapSpec(
        initialSnap: widget.initialExtent,
        snappings: [widget.minExtent, widget.initialExtent, widget.expandedExtent],
      ),
      listener: sheetStateListener,
      headerBuilder: (context, state){
        return widget.header;
      },
      customBuilder: (context, controller, state){
        return SingleChildScrollView(
          physics: widget.disableSheetScroll ? NeverScrollableScrollPhysics() : AlwaysScrollableScrollPhysics(),
          controller: controller,
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Navigator(
              key: key,
              onGenerateRoute: (settings) => MaterialPageRoute(
                settings: settings,
                builder: (context){
                  return MultiFeed(
                    sheetController: widget.controller.sheetController,
                    loaders: widget.loaders,
                    headerSliver: widget.headerSliver,
                    lengthFactor: widget.lengthFactor,
                    innitalLength: widget.innitalLength,
                    onRefresh: widget.onRefresh,
                    controller: widget.controller.multifeedController,
                    footerSliver: widget.footerSliver,
                    childBuilders: widget.childBuilders,
                    childBuilder: widget.childBuilder,
                    footerHeight: widget.footerHeight,
                    placeHolder: widget.placeHolder,
                    placeHolders: widget.placeHolders,
                    loading: widget.loading,
                    condition: widget.condition,
                    disableScroll: widget.disableScroll,
                    headerBuilder: widget.headerBuilder,
                    wrapper: widget.wrapper,
                  );
                }
              ),
            ),
          ),
        );
      },
      footerBuilder: (context, state){
        return widget.footer;
      },
    );
  }
}

///Controller for the simple multi feed. 
///Holds a nested Page, Tab and Scroll controllers
class SlidingSheetFeedController extends ChangeNotifier {
  late _SlidingSheetFeedState? _state;

  /// Bounded to the sliding sheet
  final SheetController sheetController;

  /// State of the feed
  final MultiFeedController multifeedController;

  ///Private constructor
  SlidingSheetFeedController._(this.sheetController, this.multifeedController);

  ///Default constuctor
  ///Creates the nested controllers
  factory SlidingSheetFeedController({
    required int pageCount,
    int initialPage = 0,
    bool keepPage = true,
    double viewportFraction = 1.0,
    TickerProvider? vsync,
    List<double>? initialOffsets,
    List<bool>? keepScrollOffsets,
    List<String>? debugLabels
  }){
    return SlidingSheetFeedController._(
      SheetController(),
      MultiFeedController(
        pageCount: pageCount,
        initialPage: initialPage,
        keepPage: keepPage,
        viewportFraction: viewportFraction,
        vsync: vsync,
        initialOffsets: initialOffsets,
        keepScrollOffsets: keepScrollOffsets,
        debugLabels: debugLabels,
      )
    );
  }

  Future<dynamic> push(Widget page) => _state!.pushPage(page);

  ///Binds the feed state
  void _bind(_SlidingSheetFeedState bind) => _state = bind;

  //Called to notify all listners
  void _update() => notifyListeners();

  //Disposes of the controller and all nested controllers
  @override
  void dispose() {

    //Disconnect state
    _state = null;
    
    //Dispose all nested controllers
    multifeedController.dispose();

    super.dispose();
  }
}