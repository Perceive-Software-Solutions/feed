
import 'package:flutter/material.dart';

///Container for all app color values
class AppColor {
  final Color? primary;
  final Color? primaryVariant;
  final Color? red;
  final Color? redVariant;
  final Color? blue;
  final Color? background;
  final Color? surface;
  final Color? onPrimary;
  final Color? onBackground;
  final Color? white;
  final Color? whiteVariant;
  final Color? grey;
  final Color? greyVariant;
  final Color? dark;
  final Color? darkVariant;
  final Color? yellow;

  AppColor({this.primary, 
    this.primaryVariant, 
    this.red, 
    this.redVariant, 
    this.blue, 
    this.background, 
    this.surface, 
    this.onPrimary, 
    this.onBackground, 
    this.white, 
    this.whiteVariant, 
    this.grey, 
    this.greyVariant, 
    this.dark, 
    this.darkVariant,
    this.yellow});
}

///Light theme for the application
final AppColor lightTheme = AppColor(
  primary: Color(0xFF192A56),
  primaryVariant: Color(0xFF273C75),
  red: Color(0xFFC23616),
  redVariant: Color(0xFFE84118),
  blue: Color(0xFF285FD7),
  background: Color(0xFFEFF5FA),
  surface: Color(0xFFF7FAFD),
  onPrimary: Colors.white,
  onBackground: Colors.black,
  white: Color(0xFFDCDDE1),
  whiteVariant: Color(0xFFF5F6FA),
  grey: Color(0xFF718093),
  greyVariant: Color(0xFF7F8FA6),
  dark: Color(0xFF2F3640),
  darkVariant: Color(0xFF353B48),
  yellow: Color(0xFFFFCC00)
);

//TODO: Dark theme

///Provides the color theme to the application. 
///Utilizes the app color controller to change the theme
class ColorProvider extends InheritedWidget with WidgetsBindingObserver {

  final Brightness appTheme;
  final AppColor color;

  ColorProvider({Key? key, Widget? child, required this.appTheme}) :
  color = appTheme == Brightness.light ? lightTheme : lightTheme , 
  super(key: key, child: child!);

  static AppColor of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ColorProvider>()?.color ?? lightTheme;
  }

  ///Updates if the apptheme updates
  @override
  bool updateShouldNotify(ColorProvider oldWidget) => appTheme != oldWidget.appTheme;

}

///Provides the app with an inherited color provider. 
///Listens to changes in the system brightness to update the app accordingly.
class AppColorThemeController extends StatefulWidget {

  final Widget child;

  const AppColorThemeController({Key? key, required this.child}) : super(key: key);

  @override
  _AppColorThemeControllerState createState() => _AppColorThemeControllerState();
}

class _AppColorThemeControllerState extends State<AppColorThemeController> with WidgetsBindingObserver {

  Brightness? appTheme;

  @override
  void initState() {
    super.initState();
    //Binds this as a listner to the widgets binnding and populates the innitial system brigtness value
    appTheme = WidgetsBinding.instance!.window.platformBrightness;
    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  void dispose() {
    //Removes this from the observers list
    WidgetsBinding.instance!.removeObserver(this);

    super.dispose();
  }

  @override
  //Called when the system brightness updates, update app theme
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();

    setState(() {
      appTheme = WidgetsBinding.instance!.window.platformBrightness;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColorProvider(
      appTheme: appTheme!,
      child: widget.child,
    );
  }
}