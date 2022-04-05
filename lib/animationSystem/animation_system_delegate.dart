part of './animation_system_delegate_builder.dart';

abstract class AnimationSystemDelegate {
  
  Widget build(BuildContext context, IconPosition? iconPosition, CardPosition? cardPosition, double fill);
}