// Synthetic arithmetic oracle: hand-derived constants only.
// Intentionally imports neither scorer, models, validator nor fixtures.
// These are component expectations, not eligible partial member profiles.
class OracleRational {
  final int numerator;
  final int denominator;
  const OracleRational(this.numerator, [this.denominator = 1]);
}

class OracleContributions {
  final OracleRational earned;
  final int available;
  final OracleRational overall;
  const OracleContributions(this.earned, this.available, this.overall);
}

// A scalar has one available unit; Green=1, Amber=1/2, Red=0.
const scalarGreen = OracleContributions(
  OracleRational(1),
  1,
  OracleRational(1),
);
const scalarAmber = OracleContributions(
  OracleRational(1, 2),
  1,
  OracleRational(1, 2),
);
const scalarRed = OracleContributions(OracleRational(0), 1, OracleRational(0));

// One two-selection question: (1 + 0) / 2 = 1/2, not two units.
const greenRedQuestion = OracleContributions(
  OracleRational(1, 2),
  1,
  OracleRational(1, 2),
);
// (1/2 + 1/2) / 2 = 1/2; both lights are Amber, so the pattern is Open.
const twoAmberQuestion = OracleContributions(
  OracleRational(1, 2),
  1,
  OracleRational(1, 2),
);
// 1/2 + 1 = 3/2 earned across two questions; (3/2) / 2 = 3/4.
const greenRedPlusGreen = OracleContributions(
  OracleRational(3, 2),
  2,
  OracleRational(3, 4),
);
// (1 + 1 + 0) / 3 + 1 = 5/3; (5/3) / 2 = 5/6.
// The two Green selections represent distinct valid options, not duplicates.
const greenGreenRedPlusGreen = OracleContributions(
  OracleRational(5, 3),
  2,
  OracleRational(5, 6),
);
// Category A's one Green and B's three Reds earn 1 across four units.
// The result is 1/4, not (A's 1 + B's 0) / 2 = 1/2.
const unequalCategoryCoverage = OracleContributions(
  OracleRational(1),
  4,
  OracleRational(1, 4),
);
// OA-ZYRA-228: two Green questions start at 2/2. Adding a valid Red option
// to one question changes only that question's mean, leaving two units.
const oa228Before = OracleContributions(
  OracleRational(2),
  2,
  OracleRational(1),
);
const oa228After = OracleContributions(
  OracleRational(3, 2),
  2,
  OracleRational(3, 4),
);
const allRedWithCoverage = OracleContributions(
  OracleRational(0),
  3,
  OracleRational(0),
);

// Chapter2 isolated branch expectations: every applicable block is currently
// one provisional unit. Valid skip/non-applicability contributes no unit.
const chapter2Green = OracleContributions(
  OracleRational(1),
  1,
  OracleRational(1),
);
const chapter2Amber = OracleContributions(
  OracleRational(1, 2),
  1,
  OracleRational(1, 2),
);
const chapter2Red = OracleContributions(
  OracleRational(0),
  1,
  OracleRational(0),
);
// Two Amber Deen units earn 1; four matching Culture units earn 4.
// All six applicable Chapter2 blocks therefore earn 5 across 6 units.
const chapter2AllSix = OracleContributions(
  OracleRational(5),
  6,
  OracleRational(5, 6),
);
