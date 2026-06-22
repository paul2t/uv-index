/// Fitzpatrick skin-type scale, used to scale the "minutes to burn" estimate.
enum SkinType {
  i,
  ii,
  iii,
  iv,
  v,
  vi;

  /// Multiplier in the burn-time heuristic — higher means slower burning.
  double get burnFactor {
    switch (this) {
      case SkinType.i:
        return 1.5;
      case SkinType.ii:
        return 2.0;
      case SkinType.iii:
        return 3.0;
      case SkinType.iv:
        return 4.5;
      case SkinType.v:
        return 6.0;
      case SkinType.vi:
        return 8.0;
    }
  }

  String get label {
    switch (this) {
      case SkinType.i:
        return 'Type I — Very fair, always burns';
      case SkinType.ii:
        return 'Type II — Fair, burns easily';
      case SkinType.iii:
        return 'Type III — Medium, sometimes burns';
      case SkinType.iv:
        return 'Type IV — Olive, rarely burns';
      case SkinType.v:
        return 'Type V — Brown, very rarely burns';
      case SkinType.vi:
        return 'Type VI — Dark brown/black, never burns';
    }
  }
}

/// A user-chosen location override, replacing GPS.
class ManualLocation {
  final double latitude;
  final double longitude;
  final String label;

  const ManualLocation({
    required this.latitude,
    required this.longitude,
    required this.label,
  });
}
