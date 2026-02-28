bool versionNewerThan(String version1, String version2) {
  final version1Parts = version1.split('.');
  final version2Parts = version2.split('.');
  for (int i = 0; i < version1Parts.length; i++) {
    if (int.parse(version1Parts[i]) > int.parse(version2Parts[i])) {
      return true;
    } else if (int.parse(version1Parts[i]) < int.parse(version2Parts[i])) {
      return false;
    }
  }
  return false;
}
