import 'dart:io';

/// Checks if the contents of [selectedFile] are byte-by-byte identical to any existing
/// cover file in [appDir]. Returns the absolute path of the existing file if a match is found,
/// otherwise returns null.
Future<String?> findExistingMatchingCover(File selectedFile, Directory appDir) async {
  try {
    if (!selectedFile.existsSync()) return null;
    final selectedBytes = await selectedFile.readAsBytes();
    final selectedLength = selectedBytes.length;

    final files = appDir.listSync();
    for (final entity in files) {
      if (entity is File) {
        final filename = entity.path.split('/').last.split('\\').last;
        // Check files starting with 'cover_'
        if (filename.startsWith('cover_')) {
          if (entity.lengthSync() == selectedLength) {
            final existingBytes = await entity.readAsBytes();
            bool isIdentical = true;
            for (int i = 0; i < selectedLength; i++) {
              if (selectedBytes[i] != existingBytes[i]) {
                isIdentical = false;
                break;
              }
            }
            if (isIdentical) {
              return entity.path;
            }
          }
        }
      }
    }
  } catch (_) {
    // Ignore issues reading other files and fall back to copying
  }
  return null;
}
