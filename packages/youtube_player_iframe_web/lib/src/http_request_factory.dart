import 'package:http/browser_client.dart';
import 'package:http/http.dart' show Response;
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

/// Factory class for creating [HttpRequest] instances.
class HttpRequestFactory {
  /// Creates a [HttpRequestFactory].
  const HttpRequestFactory();

  /// Creates and sends a URL request for the specified [url].
  Future<Response> request(
    Uri uri, {
    required LoadRequestMethod method,
    Map<String, String>? headers,
    Object? body,
  }) async {
    final client = BrowserClient();

    return switch (method) {
      LoadRequestMethod.get => client.get(uri, headers: headers),
      LoadRequestMethod.post => client.post(uri, headers: headers, body: body),
    };
  }
}
