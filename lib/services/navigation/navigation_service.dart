import 'package:conoll/services/chat/room/Room.dart';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:conoll/animations/Shared_Axis.dart';

import 'package:conoll/pages/Login/Login_Page.dart';
import 'package:conoll/pages/Login/SignUp_Page.dart';
import 'package:conoll/pages/Home_Page.dart';
import 'package:conoll/pages/Chat/Chat_page.dart';

enum AppDestination { login, signup, home }

class NavigationService {
  static void navigateTo({
    required BuildContext context,
    required AppDestination destination,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    bool sharedAxis = false,
    SharedAxisTransitionType transitionType =
        SharedAxisTransitionType.horizontal,
  }) {
    switch (destination) {
      case AppDestination.login:
        _pushPage(context, const LoginPage(), sharedAxis, transitionType);
        break;
      case AppDestination.signup:
        _pushPage(context, const SignUpPage(), sharedAxis, transitionType);
        break;
      case AppDestination.home:
        _pushPage(context, const HomePage(), sharedAxis, transitionType);
        break;
    }
  }

  static void openChat({
    required BuildContext context,
    bool sharedAxis = false,
    SharedAxisTransitionType transitionType =
        SharedAxisTransitionType.horizontal,
    required Room room,
  }) {
    _pushPage(context, ChatPage(room: room), sharedAxis, transitionType);
  }

  static void _pushPage(
    BuildContext context,
    Widget page,
    bool sharedAxis,
    SharedAxisTransitionType transitionType,
  ) {
    Navigator.push(
      context,
      sharedAxis
          ? SharedAxisPageRoute(child: page, transitionType: transitionType)
          : MaterialPageRoute(builder: (context) => page),
    );
  }
}
