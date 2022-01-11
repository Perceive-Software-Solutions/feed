
import 'dart:ui';

import 'package:feed/feed.dart';
import 'package:feed/util/global/functions.dart';
import 'package:feed/util/state/concrete_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_neumorphic_null_safety/flutter_neumorphic.dart';
import 'package:perceive_slidable/sliding_sheet.dart';

/// Uses package [SlidingSheet] and widget [MultiFeed]
/// Creates a multi feed that can manage its own context and list inside of a bottom modal sheet
/// *** The sliding of the list relative to the sliding sheet can not currently be 
class SlidingSheetFeed extends StatefulWidget {

  /// Cintroller for the sheet and the multi feed within
  final SlidingSheetFeedController controller;

  ///If toggled ensures that the sheet controls the scroll body until expansion
  final bool staticSheet;

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
  final Widget Function(BuildContext context, dynamic pageObject, Widget spacing)? header;

  /// Footer of the sheet
  final Widget Function(BuildContext context, dynamic pageObject)? footer;

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

  /// Child builder
  final MultiFeedBuilder? childBuilder;

  ///defines the height to offset the body
  final double? footerHeight;

  ///Disables the scroll controller when set to true
  final bool? disableScroll;

  /// Condition to hidefeed
  final bool? condition;

  /// Loading state placeholders
  final List<Widget> Function(double extent, double headerHeight)? placeHolders;

  /// Loading widget
  final Widget? loading;

  /// Corresponds to the [condition] and replaces feed with [Widget]
  final Widget? placeHolder;

  ///The header builder that prints over each multi feed
  final Widget Function(BuildContext context, int feedIndex)? headerBuilder;

  ///The optional function used to wrap the list view
  final IndexWidgetWrapper? wrapper;

  /// HeaderHeight
  final double headerHeight;
  
  ///Retreives the item id, used to ensure the prevention of duplcicate additions
  final String Function(dynamic item)? getItemID;

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
    this.header,
    this.footer,
    this.disableSheetScroll = false,
    this.headerSliver,
    this.lengthFactor,
    this.innitalLength,
    this.onRefresh,
    this.footerSliver,
    this.childBuilder,
    this.footerHeight,
    this.placeHolders,
    this.placeHolder,
    this.loading,
    this.condition = false, 
    this.disableScroll, 
    this.headerBuilder,
    this.wrapper,
    this.getItemID,
    this.headerHeight = 60,
    this.staticSheet = false
  }) : super(key: key);

  @override
  _SlidingSheetFeedState createState() => _SlidingSheetFeedState();
}

class _SlidingSheetFeedState extends State<SlidingSheetFeed> {

  GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  late ConcreteCubit<dynamic> pageObject = ConcreteCubit<dynamic>(null);

  late ConcreteCubit<double> sheetExtent = ConcreteCubit<double>(widget.initialExtent);

  ConcreteCubit<double> headerHeight = ConcreteCubit<double>(70);

  BuildContext? heightContext;

  double statusBarHeight = 0.0;

  double mainExtent = 0.0;

  late bool disableSheet = widget.staticSheet;

  late SlidingSheetStateController slidingSheetStateController;

  @override
  void initState(){
    super.initState();

    slidingSheetStateController = SlidingSheetStateController();

    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) { 
      if(heightContext != null){
        headerHeight.emit(heightContext!.size!.height);
      }
    });
  }

  void refreshHeight(){
    if(heightContext != null){
        double value = MediaQueryData.fromWindow(window).padding.top * (Functions.animateOver(sheetExtent.state, percent: 0.9));
        if(!value.isNegative){
          headerHeight.emit(heightContext!.size!.height - value);
        }
        else{
          headerHeight.emit(heightContext!.size!.height);
        }
    }
  }

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
    else if(disableSheet && state.extent >= widget.expandedExtent){
      setState(() {
        disableSheet = false;
      });
    }
    else if(!disableSheet && state.extent < widget.expandedExtent && widget.staticSheet){
      setState(() {
        disableSheet = true;
      });
    }
    mainExtent = state.extent;
    sheetExtent.emit(state.extent);
    widget.controller._update();
  }

  Future<dynamic> pushPage(Widget page, [dynamic pageObj]) {
    pageObject.emit(pageObj);
    return key.currentState!.push(MaterialPageRoute(builder: (context) => page,));
  }

  void popPage(){
    key.currentState!.pop(pageObject);
    pageObject.emit(null);
  }


  @override
  Widget build(BuildContext context) {
    statusBarHeight = MediaQueryData.fromWindow(window).padding.top;
    return SlidingSheet(
      controller: widget.controller.sheetController,
      color: widget.color,
      closeSheetOnBackButtonPressed: widget.closeOnBackButtonPressed,
      closeOnBackdropTap: widget.closeOnBackdropTap, //Closes the page when the sheet reaches the bottom
      extendBody: widget.extendBody,
      cornerRadius: widget.cornerRadius,
      cornerRadiusWhenExpanded: widget.cornerRadiusOnFullscreen,
      duration: widget.duration,
      slidingSheetStateController: slidingSheetStateController,
      snapSpec: SnapSpec(
        initialSnap: widget.initialExtent,
        snappings: [widget.minExtent, widget.initialExtent, widget.expandedExtent],
      ),
      listener: sheetStateListener,
      customBuilder: (context, controller, state){
        return Navigator(
          key: key,
          onGenerateRoute: (settings) => MaterialPageRoute(
            settings: settings,
            builder: (context){
              Widget header = BlocBuilder<ConcreteCubit<dynamic>, dynamic>(
                bloc: pageObject,
                builder: (context, obj) {
                  return BlocBuilder<ConcreteCubit<double>, double>(
                    bloc: sheetExtent,
                    builder: (context, extent){
                      heightContext = context;
                      //The animation value for the topExtent animation
                      double topExtentValue = Functions.animateOver(extent, percent: 0.9);
                      return widget.header!(context, obj, Container(height: lerpDouble(0, statusBarHeight, topExtentValue)),);
                    },
                  );
                }      
              );
              return Stack(
                children: [
                  widget.header != null ? 
                  slidingSheetStateController.delegateInteractions(header) ?? header : 
                  SizedBox.shrink(),

                  BlocBuilder<ConcreteCubit<double>, double>(
                    bloc: headerHeight,
                    builder: (context, hHeight) {
                      return BlocBuilder<ConcreteCubit<double>, double>(
                        bloc: sheetExtent,
                        builder: (context, sheetExtentValue) {
                          double topExtentValue = Functions.animateOver(sheetExtentValue, percent: 0.9);
                          double pageHeight = MediaQuery.of(context).size.height;
                          double height = sheetExtentValue > 0.8 ? 
                          pageHeight*sheetExtentValue - hHeight - statusBarHeight :  
                          pageHeight*sheetExtentValue - hHeight;
                          if(height < 0){
                            height = 100;
                          }
                          return Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Container(height: hHeight + lerpDouble(0, statusBarHeight, topExtentValue)!),
                              Expanded(
                                child: SingleChildScrollView(
                                  physics: widget.disableSheetScroll ? NeverScrollableScrollPhysics() : AlwaysScrollableScrollPhysics(),
                                  controller: controller,
                                  child: SizedBox(
                                    height: height,
                                    child: MultiFeed(
                                      sheetController: widget.controller.sheetController,
                                      loaders: widget.loaders,
                                      headerSliver: widget.headerSliver,
                                      lengthFactor: widget.lengthFactor,
                                      innitalLength: widget.innitalLength,
                                      onRefresh: widget.onRefresh,
                                      controller: widget.controller.multifeedController,
                                      footerSliver: widget.footerSliver,
                                      extent: widget.initialExtent,
                                      minExtent: widget.minExtent,
                                      childBuilder: widget.childBuilder,
                                      footerHeight: widget.footerHeight,
                                      placeHolder: widget.placeHolder,
                                      placeHolders: widget.placeHolders?.call(mainExtent, hHeight) ?? [],
                                      loading: widget.loading,
                                      condition: widget.condition,
                                      disableScroll: disableSheet || (widget.disableScroll ?? false),
                                      headerBuilder: widget.headerBuilder,
                                      wrapper: widget.wrapper,
                                      getItemID: widget.getItemID,
                                    ) 
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                      );
                    }
                  ),
                ],
              );
            }
          ),
        );
      },
      footerBuilder: (context, state){
        return widget.footer != null ? BlocBuilder<ConcreteCubit<dynamic>, dynamic>(
          bloc: pageObject,
          builder: (context, obj) {
            return widget.footer!(context, obj);
          }
        ) : SizedBox.shrink();
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
    List<String>? debugLabels,
    FeedGridViewDelegate? Function(int index)? gridDelegateGenerator,
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
        indexedGridDelegates: Map<int, FeedGridViewDelegate?>.fromIterable(
          List.generate(pageCount, (i) => i),
          key: (e) => e,
          value: (e) => gridDelegateGenerator?.call(e)
        )
      )
    );
  }



  Future<dynamic> push(Widget page, [dynamic pageObj]) => _state!.pushPage(page, pageObj);

  void pop() => _state!.popPage();

  ///Binds the feed state
  void _bind(_SlidingSheetFeedState bind) => _state = bind;

  //Called to notify all listners
  void _update() => notifyListeners();

  void refreshHeight() => _state != null ? _state!.refreshHeight() : null;

  Widget? delegateInderations(Widget child) => _state != null ? _state!.slidingSheetStateController.delegateInteractions(child) : null;

  double get extent => _state != null ? _state!.mainExtent : 0.0;

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