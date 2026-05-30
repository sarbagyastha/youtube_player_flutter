// Copyright 2022 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

/// Factory class for creating web requests.
class HttpRequestFactory {
  /// Creates a [HttpRequestFactory].
  const HttpRequestFactory();

  /// Creates and sends a URL request for the specified [url].
  Future<Response> request(
    Uri uri, {
    required LoadRequestMethod method,
    Map<String, String>? headers,
    Uint8List? data,
  }) async {
    final request = RequestInit(
      method: method.serialize(),
      headers: headers.jsify()! as HeadersInit,
      body: data?.toJS,
    );

    return window.fetch(uri.toString().toJS, request).toDart;
  }
}
