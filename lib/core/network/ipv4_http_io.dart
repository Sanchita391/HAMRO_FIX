import 'dart:io';

void installIpv4PreferredNetworking() {
  HttpOverrides.global = _Ipv4HttpOverrides();
}

class _Ipv4HttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context)
      ..idleTimeout = const Duration(minutes: 2)
      ..connectionTimeout = const Duration(seconds: 45);
    client.connectionFactory = (uri, proxyHost, proxyPort) async {
      if (proxyHost != null && proxyPort != null) {
        return Socket.startConnect(proxyHost, proxyPort);
      }
      final port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
      final ipv4 = await InternetAddress.lookup(
        uri.host,
        type: InternetAddressType.IPv4,
      );
      if (ipv4.isEmpty) {
        return Socket.startConnect(uri.host, port);
      }
      return Socket.startConnect(ipv4.first, port);
    };
    return client;
  }
}
