class RateLimiter {
  final int maxRequests;
  final Duration duration;
  final Map<String, List<DateTime>> _clientRequests = {};

  RateLimiter(this.maxRequests, this.duration);

  int requestCount(String clientIP) {
    final requests = _clientRequests[clientIP];
    return requests?.length ?? 0;
  }

  bool isRateLimited(String clientIP) {
    final now = DateTime.now();
    final requests = _clientRequests.putIfAbsent(clientIP, () => []);
    requests.removeWhere((time) => now.difference(time) > duration);

    if (requests.length >= maxRequests) {
      return true;
    }

    requests.add(now);
    return false;
  }
}
