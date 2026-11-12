/// DR-ZYRA-250 D3 defines the display order and names.
enum ZyraCompatibilityArea {
  deen('Deen & Islamic Practice'),
  marriage('Marriage Intentions & Structure'),
  children('Children & Parenting'),
  family('Family & In-Laws'),
  finances('Finances & Provision'),
  work('Education, Career & Work'),
  home('Home Life & Household Roles'),
  communication('Communication & Conflict'),
  personality('Personality & Connection'),
  lifestyle('Lifestyle, Health & Well-being'),
  digital('Digital Life, Privacy & Boundaries'),
  culture('Culture & Language');

  const ZyraCompatibilityArea(this.label);

  final String label;
}

/// Display codes only. Area calculations and thresholds belong to the server.
enum ZyraCompatibilityBand {
  strong('Strong'),
  good('Good'),
  someDifferences('Some differences'),
  notEnoughAnswers('Not enough answers');

  const ZyraCompatibilityBand(this.label);

  final String label;
}
