part of './animation_system_delegate_builder.dart';

/// Animation Design
abstract class AnimationSystemDelegate {

  final bool animateAccordingToPosition;
  final Duration duration;

  AnimationSystemDelegate({this.animateAccordingToPosition = false, this.duration = const Duration(milliseconds: 600)});

  Widget build(BuildContext context, AnimationSystemState state, double fill);
  void onUpdate(double dx, double dy, double value);
  Future<void> onFill(double? fill, AnimationSystemState state);
  Future<bool> onComplete(AnimationSystemState state, {OverlayDelegate? overlay, Future<void> Function()? reverse, List<dynamic>? args});
}

/// Overlay Design
abstract class OverlayDelegate{

  OverlayDelegate();

  Widget build(Completer<bool> result, Future<void> Function() reverse, {List<dynamic>? args});
}