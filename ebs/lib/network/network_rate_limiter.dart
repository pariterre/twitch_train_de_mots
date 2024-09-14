class NetworkRateLimiter {
  final int maxRequests;
  final Duration duration;
  final Map<String, List<DateTime>> _clientRequests = {};

  NetworkRateLimiter(this.maxRequests, this.duration);

  int requestCount(String clientIp) {
    final requests = _clientRequests[clientIp];
    return requests?.length ?? 0;
  }

  bool isRateLimited(String clientIp) {
    final now = DateTime.now();
    final requests = _clientRequests.putIfAbsent(clientIp, () => []);
    requests.removeWhere((time) => now.difference(time) > duration);

    if (requests.length >= maxRequests) {
      return true;
    }

    requests.add(now);
    return false;
  }
}
