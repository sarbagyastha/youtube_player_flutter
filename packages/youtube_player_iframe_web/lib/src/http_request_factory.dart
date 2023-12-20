import 'package:web/helpers.dart';

/// Factory class for creating [HttpRequest] instances.
class HttpRequestFactory {
  /// Creates a [HttpRequestFactory].
  const HttpRequestFactory();

  /// Creates and sends a URL request for the specified [url].
  Future<XMLHttpRequest> request(
    String url, {
    String? method,
    bool? withCredentials,
    String? responseType,
    String? mimeType,
    Map<String, String>? requestHeaders,
    Object? sendData,
    void Function(ProgressEvent)? onProgress,
  }) {
    return HttpRequest.request(
      url,
      method: method,
      withCredentials: withCredentials,
      responseType: responseType,
      mimeType: mimeType,
      requestHeaders: requestHeaders,
      sendData: sendData,
      onProgress: onProgress,
    );
  }
}
