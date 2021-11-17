import 'package:feed/feed.dart';
import 'package:feed/util/global/functions.dart';
import 'package:flutter/material.dart';
import 'package:sliding_sheet/sliding_sheet.dart';
import 'package:tuple/tuple.dart';

/// Uses package [SlidingSheet] and widget [SimpleMultiFeed]
/// Creates a multi feed that can manage its own context and list inside of a bottom modal sheet
/// *** The sliding of the list relative to the sliding sheet can not currently be 
class SlidingSheetFeed extends StatefulWidget {

  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Sliding Sheet ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  /// Bounded to the sliding sheet
  final SheetController sheetController;

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

  /// Body of the sheet
  final Widget body;

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

  /// State of the feed
  final SimpleMultiFeedController? controller;

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

  const SlidingSheetFeed({ 
    Key? key,
    required this.sheetController,
    required this.loaders,
    required this.body,
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
    this.controller,
    this.footerSliver,
    this.childBuilders,
    this.childBuilder,
    this.footerHeight,
    this.placeHolders,
    this.placeHolder,
    this.loading,
    this.condition = false, 
    this.disableScroll, 
    this.headerBuilder
  }) : super(key: key);

  @override
  _SlidingSheetFeedState createState() => _SlidingSheetFeedState();
}

class _SlidingSheetFeedState extends State<SlidingSheetFeed> {


  void sheetStateListener(SheetState state){

    if(state.extent == 0.0){
      if(Navigator.canPop(context)){
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlidingSheet(
      controller: widget.sheetController,
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
          child: SimpleMultiFeed(
            loaders: widget.loaders,
            headerSliver: widget.headerSliver,
            lengthFactor: widget.lengthFactor,
            innitalLength: widget.innitalLength,
            onRefresh: widget.onRefresh,
            controller: widget.controller,
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
          ),
        );
      },
      footerBuilder: (context, state){
        return widget.footer;
      },
    );
  }
}