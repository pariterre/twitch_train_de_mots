import 'package:train_de_mots_ebs/network/network_rate_limiter.dart';

class NetworkParameters {
  final String host;
  final int port;

  bool get usingSecure =>
      certificatePath?.isNotEmpty == true && privateKeyPath?.isNotEmpty == true;
  final String? certificatePath;
  final String? privateKeyPath;

  final rateLimiter = NetworkRateLimiter(100, Duration(minutes: 1));

  NetworkParameters({
    required this.host,
    required this.port,
    this.certificatePath,
    this.privateKeyPath,
  });
}
