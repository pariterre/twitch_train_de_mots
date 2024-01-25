class ReleaseNotes {
  final String version;
  final String? codeName;
  final String? notes;
  final List<FeatureNotes> features;

  const ReleaseNotes(
      {required this.version,
      this.codeName,
      this.notes,
      this.features = const []});
}

class FeatureNotes {
  final String description;
  final String? userWhoRequested;

  const FeatureNotes({required this.description, this.userWhoRequested});
}
