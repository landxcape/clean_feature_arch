import 'package:path/path.dart' as p;

/// Utilities for architectural linting.
class AbsoluteRuleUtils {
  const AbsoluteRuleUtils._();

  static bool isFeatureFile(String path) => path.contains('lib/features/');

  static String? getFeatureName(String path) {
    if (!isFeatureFile(path)) return null;
    final parts = p.split(path);
    final featuresIndex = parts.indexOf('features');
    if (featuresIndex != -1 && featuresIndex + 1 < parts.length) {
      return parts[featuresIndex + 1];
    }
    return null;
  }

  static bool isInLayer(String path, String layerName) {
    final featureName = getFeatureName(path);
    if (featureName == null) return false;
    return path.contains('lib/features/$featureName/$layerName/');
  }

  static bool isDomain(String path) => isInLayer(path, 'domain');
  static bool isData(String path) => isInLayer(path, 'data');
  static bool isPresentation(String path) => isInLayer(path, 'presentation');

  static bool isCore(String path) => path.contains('lib/core/');
  static bool isShared(String path) => path.contains('lib/shared/');
}
