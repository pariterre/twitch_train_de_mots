dynamic deepDiffAsPatch(dynamic oldValue, dynamic newValue) {
  // TODO Validate this
  if (oldValue is Map && newValue is Map) {
    final diff = <String, dynamic>{};

    final keys = {...oldValue.keys, ...newValue.keys};

    for (final key in keys) {
      if (!oldValue.containsKey(key)) {
        diff[key] = newValue[key]; // added
      } else if (!newValue.containsKey(key)) {
        diff[key] = null; // removed
      } else {
        final subDiff = deepDiffAsPatch(oldValue[key], newValue[key]);
        if (subDiff != null) {
          diff[key] = subDiff;
        }
      }
    }

    return diff.isEmpty ? null : diff;
  }

  if (oldValue is List && newValue is List) {
    if (oldValue.length != newValue.length) {
      return newValue;
    }
    for (int i = 0; i < oldValue.length; i++) {
      final subDiff = deepDiffAsPatch(oldValue[i], newValue[i]);
      if (subDiff != null) {
        return newValue; // treat list as atomic, any change means the whole list is changed
      }
    }
    return null;
  }

  if (oldValue != newValue) {
    return newValue;
  }

  return null;
}

dynamic applyPatch(dynamic oldValue, dynamic patch) {
  if (oldValue == null) throw 'Cannot apply patch to null old value';
  if (patch == null) return oldValue; // no changes

  if (oldValue is Map && patch is Map) {
    final result = Map<String, dynamic>.from(oldValue);

    for (final key in patch.keys) {
      if (patch[key] == null) {
        result.remove(key); // removed
      } else if (!oldValue.containsKey(key)) {
        result[key] = patch[key]; // added
      } else {
        result[key] = applyPatch(oldValue[key], patch[key]);
      }
    }

    return result;
  }

  if (patch is List) {
    return patch; // treat list as atomic
  }

  return patch; // primitive value changed
}
