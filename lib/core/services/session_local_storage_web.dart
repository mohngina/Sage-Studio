import 'package:web/web.dart';

String? sessionGetItem(String key) => window.sessionStorage.getItem(key);

void sessionSetItem(String key, String value) =>
    window.sessionStorage.setItem(key, value);

void sessionRemoveItem(String key) => window.sessionStorage.removeItem(key);

void localRemoveItem(String key) => window.localStorage.removeItem(key);
