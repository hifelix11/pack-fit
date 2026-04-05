import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// True when running inside a browser tab.
bool get isWeb => kIsWeb;

/// True on iOS (not web).
bool get isIos => !kIsWeb && Platform.isIOS;

/// True on Android (not web).
bool get isAndroid => !kIsWeb && Platform.isAndroid;

/// True on any mobile platform (not web).
bool get isMobile => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

/// Max content width on web to keep the layout phone-like.
const double webMaxContentWidth = 480;
