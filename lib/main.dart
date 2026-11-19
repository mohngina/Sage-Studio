import 'package:flutter/material.dart';
import 'app.dart';
import 'core/services/auth_service.dart';
import 'core/services/portal_repositories.dart';
import 'features/shop/cart_controller.dart';
import 'features/shop/favourites_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Reference FavouritesController before AuthService.initialise() so its
  // sign-in hook is registered, and ensure customer profile exists on sign-in.
  FavouritesController.instance;
  AuthService.instance.addSignInHook((_) => ProfileRepository().fetchOrCreate());
  await AuthService.instance.initialise();
  await CartController.instance.initialise();
  runApp(const SageStudioApp());
}
