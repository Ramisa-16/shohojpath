/// The four Bangla typefaces offered on the Reading Settings screen.
///
/// The mockup is explicit that this is a *comfort preference*, not an
/// evidence-based control ("Research has not shown any single font improves
/// reading accuracy") — but participants must still be able to switch, and the
/// choice has to be logged, because conjunct rendering differs between these
/// faces and that is worth reporting.
enum BanglaFont {
  notoSansBengali(
    id: 'noto_sans_bengali',
    family: 'NotoSansBengali',
    label: 'Noto Sans Bengali',
    hasRealBold: true,
  ),
  solaimanLipi(
    id: 'solaiman_lipi',
    family: 'SolaimanLipi',
    label: 'SolaimanLipi',
    hasRealBold: true,
  ),
  kalpurush(
    id: 'kalpurush',
    family: 'Kalpurush',
    label: 'Kalpurush',
    hasRealBold: false,
  ),
  adorshoLipi(
    id: 'adorsho_lipi',
    family: 'AdorshoLipi',
    label: 'AdorshoLipi',
    hasRealBold: false,
  );

  const BanglaFont({
    required this.id,
    required this.family,
    required this.label,
    required this.hasRealBold,
  });

  /// Stable key for the log / CSV export.
  final String id;

  /// The `family:` name declared in pubspec.yaml.
  final String family;

  final String label;

  /// False when only one weight ships, so Flutter synthesises bold. Worth
  /// knowing before reading anything into a "bold text" condition.
  final bool hasRealBold;

  static BanglaFont fromId(String? id) => values.firstWhere(
        (f) => f.id == id,
        orElse: () => BanglaFont.notoSansBengali,
      );
}
