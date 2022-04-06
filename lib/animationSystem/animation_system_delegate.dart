part of './animation_system_delegate_builder.dart';

abstract class AnimationSystemDelegate {
  Widget build(BuildContext context, AnimationSystemState state, double fill);
  void onUpdate(double dx, double dy, double value);
  void onFill(double? fill, AnimationSystemState state);
}