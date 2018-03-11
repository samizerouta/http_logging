http_logging
============

A [HTTP client](https://github.com/dart-lang/http) middleware which logs request and response data.

```dart
import 'dart:async';

import 'package:http/http.dart';
import 'package:http_logging/http_logging.dart';

Future<Null> main() async {
  Client loggingClient = new LoggingClient(
      // Wrap a Client to log all its requests and responses.
      new Client(),
      // Select the log level between basic (default), headers, and body.
      level: LoggingLevel.body,
      // Pass in a logger, by default it uses the print method.
      logger: (msg) => print("HTTP: $msg"));

  await loggingClient.read('https://www.dartlang.org/');
}
```

It's highly inspired by the [OkHTTP logging interceptor](https://github.com/square/okhttp/tree/master/okhttp-logging-interceptor).