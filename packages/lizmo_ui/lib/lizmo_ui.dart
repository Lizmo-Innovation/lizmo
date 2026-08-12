/// Lizmo's design system — the single source of truth for
/// `docs/lizmo_design_language_v2.html`.
///
/// Both clients depend on this: the role-aware mobile app (landlord / tenant /
/// staff) and the admin web app. Anything visual that both could need belongs
/// here, so the two never drift apart.
library;

export 'src/theme/lizmo_colors.dart';
export 'src/theme/lizmo_type.dart';
export 'src/widgets/lattice_header.dart';
export 'src/widgets/primary_action_button.dart';
export 'src/widgets/status_chip.dart';
export 'src/widgets/tenant_card.dart';
