import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'app.dart';
import 'core/services/auth_service.dart';
import 'core/services/portal_repositories.dart';
import 'features/shop/cart_controller.dart';
import 'features/shop/favourites_controller.dart';

Future<void> main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  // Reference FavouritesController and CartController before AuthService.initialise()
  // so their sign-in/sign-out hooks are registered upfront.
  FavouritesController.instance;
  CartController.instance;
  AuthService.instance.addSignInHook((_) => ProfileRepository().fetchOrCreate());
  runApp(const SageStudioApp());
  // Initialise auth & cart after first frame so the UI renders immediately.
  AuthService.instance.initialise().then((_) => CartController.instance.initialise());
}
