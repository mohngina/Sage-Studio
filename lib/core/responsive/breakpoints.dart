import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet, desktop, wideDesktop }

class Breakpoints {
  static const double mobileMax = 767.0;
  static const double tabletMax = 1099.0;
  static const double desktopMax = 1439.0;

  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width <= mobileMax) {
      return DeviceType.mobile;
    } else if (width <= tabletMax) {
      return DeviceType.tablet;
    } else if (width <= desktopMax) {
      return DeviceType.desktop;
    } else {
      return DeviceType.wideDesktop;
    }
  }

  static bool isMobile(BuildContext context) => getDeviceType(context) == DeviceType.mobile;
  static bool isTablet(BuildContext context) => getDeviceType(context) == DeviceType.tablet;
  static bool isDesktop(BuildContext context) =>
      getDeviceType(context) == DeviceType.desktop || getDeviceType(context) == DeviceType.wideDesktop;
}
