part of './animation_system_delegate_builder.dart';

abstract class AnimationSystemDelegate {

  final bool animateAccordingToPosition;
  final Duration duration;

  AnimationSystemDelegate({this.animateAccordingToPosition = false, this.duration = const Duration(milliseconds: 600)});

  Widget build(BuildContext context, AnimationSystemState state, double fill);
  void onUpdate(double dx, double dy, double value);
  Future<void> onFill(double? fill, AnimationSystemState state);
  void onComplete();
}