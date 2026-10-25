# Rule 12 name-initial fix - deterministic, $0.00

Applied: 2026-08-23 (Founder decision: quick name fix, then phone test)
Base (v6): sha256 73382e1d7af679f7e4d151a4bdf3b9d4b5b840f4a9c29108d6755df4f09f582f
Candidate (v7): sha256 2c85edc0810f578f2595dbdfa03cef5ca759b836950e53d9469112afe63c388a - written to app, byte-identical

Two sites, both using the .characters.first idiom already present in this file (lines 742/945/1304):
- Discover card: full first name + age -> first-name initial + '.' + age
- Requests row: full first name -> first-name initial + '.'

Remaining OA-ZYRA-246 gaps (untouched): three approved card fields, empty profile sheet, Save action, contract v1.1.
Gate note: expression precedented in-file; formal analyze re-runs at the Founder's build (flutter run) or next engine pass.
