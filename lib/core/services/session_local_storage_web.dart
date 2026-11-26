import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('window.sessionStorage')
external JSObject get _sessionStorage;

@JS('window.localStorage')
external JSObject get _localStorage;

String? sessionGetItem(String key) =>
    (_sessionStorage.callMethod('getItem'.toJS, key.toJS) as JSString?)?.toDart;

void sessionSetItem(String key, String value) =>
    _sessionStorage.callMethod('setItem'.toJS, key.toJS, value.toJS);

void sessionRemoveItem(String key) =>
    _sessionStorage.callMethod('removeItem'.toJS, key.toJS);

void localRemoveItem(String key) =>
    _localStorage.callMethod('removeItem'.toJS, key.toJS);
