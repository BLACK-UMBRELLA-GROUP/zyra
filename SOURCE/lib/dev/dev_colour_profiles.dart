// REMOVED 2026-08-04 — Founder: "remove the 200 colour profile block
// profiles, I don't want that no more."
//
// This file held 200 deterministic colour-block profiles (100 male, 100
// female) used as a Browse deck, plus the `zyra:colour:RRGGBB` pseudo-URL
// scheme that let ZyraProfileImage paint a flat colour instead of loading
// a photograph.
//
// Why it existed, and why it no longer needs to: on 2026-08-03 the seeded
// profiles had no Chapter 2 data and their photos each needed a Storage
// signing round trip, so a synthetic deck was the fastest way to look at
// Browse with a lot of cards in it. Both reasons are now gone. The 24
// seeded profiles carry sect, ethnicity, languages and preferences, and
// they exercise the real fetch, signing and scoring path — which the
// synthetic deck never touched, and which is where the bugs actually live.
//
// Emptied rather than deleted so the removal is visible in the tree instead
// of looking like a file that was never there. Safe to delete outright.
//
// Removed alongside it:
//   zyra_dev_scenario.dart   `useColourDeck` flag
//   dev_scenario_panel.dart  the "200 colour-block profiles" switch
//   browse_screen.dart       the initState short-circuit
//   zyra_profile_image.dart  the colour-block branch
