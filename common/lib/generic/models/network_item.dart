class NetworkItem<T> {
  ///
  /// The element held by this NetworkItem.
  T _item;
  T _networkItem;

  ///
  /// Most recent item (basically ignores the synchronization flag).
  T get item => _item;

  ///
  /// Set the item and mark it as dirty for synchronization.
  set item(T newItem) {
    _item = newItem;
    _networkItem = newItem;
  }

  ///
  /// Set the item without marking it as dirty for synchronization.
  /// This should be used when the new value should not be sent over the network
  set localItem(T newItem) {
    _item = newItem;
  }

  ///
  /// The item that should be used for network synchronization. It assumes that
  /// sending this value is enough for the [item] to be fully computed from this value alone
  /// on the other side.
  T get networkItem => _networkItem;

  ///
  /// Constructor
  NetworkItem(T item)
      : _item = item,
        _networkItem = item;
}

mixin NetworkSynchronizable {
  void flushDirtyItems();

  Map<String, dynamic> serialize();
}
