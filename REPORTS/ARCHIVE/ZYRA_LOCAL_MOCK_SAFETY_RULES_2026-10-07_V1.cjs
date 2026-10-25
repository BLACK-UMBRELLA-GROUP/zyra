'use strict';
// Private fictional mock only: no application imports or network/file/provider APIs.
// Tests draft constraints, not lawfulness, live enforcement, delivery or staffing.
const assert = require('node:assert/strict');
const clone = x => JSON.parse(JSON.stringify(x));
const ORIGINAL = '2026-10-09T10:00:00.000Z'; // invented, not an actual incident
let assertions = 0;
const groups = [];
function eq(a, b, label) { assertions++; assert.deepEqual(a, b, label); }
function fixture(id) {
  return {id, receivedAt: ORIGINAL, history: [{kind: 'fixture', at: ORIGINAL}],
    status: 'BLOCKED', readers: [], dispatched: [], barriers: [],
    deliveryClaim: false, routeVerified: false, receipt: null, reviewer: null,
    actionVerified: false, closureVerified: false, appointments: [],
    priority: 'UNASSESSED', classification: 'UNDECIDED', guiltByCount: false,
    originalDecision: null, appealReviewer: null, independentClaim: false,
    lifecycleAccepted: false, deletionClaim: false, blanketHold: false,
    complaint: null, rights: null, deadlinesSelected: false,
    breachConfirmed: null, reportability: 'UNDECIDED',
    restoreClaim: false, databaseVerified: false, objectsVerified: false,
    deletionReconciled: false};
}
function violations(before, after) {
  const failures = [];
  const fail = (condition, code) => { if (condition) failures.push(code); };
  fail(before.id !== after.id, 'REFERENCE_CHANGED');
  fail(before.receivedAt !== after.receivedAt, 'CLOCK_RESET');
  fail(JSON.stringify(after.history.slice(0, before.history.length)) !==
    JSON.stringify(before.history), 'HISTORY_OVERWRITTEN');
  fail(after.barriers.length > 0, 'INTAKE_BARRIER');
  fail(after.deliveryClaim && !after.routeVerified, 'FALSE_DELIVERY');
  fail(after.status === 'ASSIGNED' && !after.receipt, 'FALSE_ASSIGNMENT');
  fail(after.status === 'REVIEWED' && (!after.receipt || !after.reviewer), 'FALSE_REVIEW');
  fail(after.status === 'ACTION_TAKEN' && !after.actionVerified, 'FALSE_ACTION');
  fail(after.status === 'CLOSED' && !after.closureVerified, 'FALSE_CLOSURE');
  // No appointed humans, granted disclosures or external actions exist in this fixture.
  fail(after.appointments.length > 0, 'INVENTED_APPOINTMENT');
  fail(after.dispatched.length > 0, 'EXTERNAL_ACTION');
  fail(after.readers.length > 0, 'UNAUTHORISED_DISCLOSURE');
  fail(after.guiltByCount, 'COUNT_IS_NOT_GUILT');
  fail(after.classification !== 'UNDECIDED', 'UNSUPPORTED_CONCLUSION');
  fail(before.originalDecision !== null && JSON.stringify(before.originalDecision) !==
    JSON.stringify(after.originalDecision), 'DECISION_OVERWRITTEN');
  fail(after.independentClaim && (!after.appealReviewer ||
    after.appealReviewer === after.originalDecision?.actor), 'FALSE_INDEPENDENCE');
  fail(after.deletionClaim && !after.lifecycleAccepted, 'LIFECYCLE_UNDECIDED');
  fail(after.blanketHold, 'BLANKET_RETENTION');
  for (const track of ['complaint', 'rights'])
    fail(before[track] && (!after[track] ||
      before[track].receivedAt !== after[track].receivedAt), track.toUpperCase() + '_CLOCK_LOST');
  fail(after.deadlinesSelected, 'APPLICABILITY_UNDECIDED');
  fail(after.breachConfirmed !== null || after.reportability !== 'UNDECIDED', 'UNASSESSED_BREACH');
  fail(after.restoreClaim && !(after.databaseVerified && after.objectsVerified &&
    after.deletionReconciled && after.lifecycleAccepted), 'INCOMPLETE_RECOVERY');
  fail(before.priority === 'URGENT_UNRESOLVED' && after.priority !== before.priority, 'URGENCY_LOST');
  return failures;
}
function safe(f) { eq(violations(f, clone(f)), [], 'safe held fixture'); }
function deny(f, change, code) {
  const proposal = clone(f); change(proposal);
  eq(violations(f, proposal).includes(code), true, code);
}
function group(id, source, body) {
  const before = assertions; body();
  groups.push({id, source, assertions: assertions - before, outcome: 'PASS_LOCAL_RULE_CHECK_ONLY'});
}
// Prepopulated fictional records only: never a claim of external intake/delivery.
function remember(book, record) {
  if (!book.has(record.id)) book.set(record.id, clone(record));
  return clone(book.get(record.id));
}
group('W01', 'Safety draft §§4–5; tabletop scenario 1', () => {
  const f = fixture('CASE-01'), book = new Map(), first = remember(book, f);
  const retry = clone(f); retry.receivedAt = '2026-10-09T11:00:00.000Z';
  eq(remember(book, retry), first, 'duplicate keeps original local record');
  eq(book.size, 1, 'one fixture'); safe(f);
  for (const [state, code] of [['ASSIGNED','FALSE_ASSIGNMENT'], ['REVIEWED','FALSE_REVIEW'],
    ['ACTION_TAKEN','FALSE_ACTION'], ['CLOSED','FALSE_CLOSURE']])
    deny(f, x => {x.status = state;}, code);
  eq(f.readers.includes('SIM-SEEKER-B'), false, 'unrelated notes denied');
  deny(f, x => {x.readers.push('SIM-SEEKER-B');}, 'UNAUTHORISED_DISCLOSURE');
});
group('W02', 'Safety draft §5 step 1 / §6; tabletop scenario 2', () => {
  for (const state of ['locked', 'deactivated', 'non-member']) {
    const f = fixture('CASE-02'); f.membership = state; safe(f);
    for (const barrier of ['login', 'payment', 'harmful-media'])
      deny(f, x => {x.barriers.push(barrier);}, 'INTAKE_BARRIER');
    deny(f, x => {x.deliveryClaim = true;}, 'FALSE_DELIVERY');
    deny(f, x => {x.dispatched.push('guardian-notification');}, 'EXTERNAL_ACTION');
  }
});
group('W03', 'Safety draft §§4–6; tabletop scenario 3', () => {
  for (const text of ['age-uncertain harmless text', 'imminent-danger harmless text']) {
    const f = fixture('CASE-03'); f.text = text; f.priority = 'URGENT_UNRESOLVED'; safe(f);
    deny(f, x => {x.priority = 'ROUTINE';}, 'URGENCY_LOST');
    deny(f, x => {x.classification = 'GUILTY';}, 'UNSUPPORTED_CONCLUSION');
    deny(f, x => {x.dispatched.push('automatic-report');}, 'EXTERNAL_ACTION');
    deny(f, x => {x.status = 'CLOSED';}, 'FALSE_CLOSURE');
  }
});
group('W04', 'Safety draft §7; tabletop scenario 4', () => {
  const f = fixture('CASE-04');
  f.originalDecision = {actor: 'SIM-UNAPPOINTED-HUMAN', outcome: 'invented contested decision'};
  safe(f);
  deny(f, x => {x.history = [];}, 'HISTORY_OVERWRITTEN');
  deny(f, x => {x.originalDecision.outcome = 'erased';}, 'DECISION_OVERWRITTEN');
  deny(f, x => {x.guiltByCount = true;}, 'COUNT_IS_NOT_GUILT');
  deny(f, x => {x.independentClaim = true; x.appealReviewer = x.originalDecision.actor;},
    'FALSE_INDEPENDENCE');
  deny(f, x => {x.readers.push('reporter-notes');}, 'UNAUTHORISED_DISCLOSURE');
});
group('W05', 'Privacy draft §6 / Safety draft §7; tabletop scenario 5', () => {
  for (const state of ['open', 'closed']) for (const role of ['reporter', 'reported']) {
    const f = fixture('CASE-05'); f.caseState = state; f.deletingRole = role; safe(f);
    deny(f, x => {x.deletionClaim = true;}, 'LIFECYCLE_UNDECIDED');
    deny(f, x => {x.blanketHold = true;}, 'BLANKET_RETENTION');
    deny(f, x => {x.readers.push('replacement-guardian');}, 'UNAUTHORISED_DISCLOSURE');
  }
});
group('W06', 'Privacy draft §9 / Safety draft §7; tabletop scenario 6', () => {
  const f = fixture('CASE-06');
  f.complaint = {receivedAt: ORIGINAL, dueAt: null};
  f.rights = {receivedAt: ORIGINAL, dueAt: null}; safe(f);
  eq(f.complaint !== f.rights, true, 'separate tracks');
  deny(f, x => {x.receivedAt = '2026-10-10T10:00:00.000Z';}, 'CLOCK_RESET');
  deny(f, x => {x.complaint.receivedAt = '2026-10-10T10:00:00.000Z';}, 'COMPLAINT_CLOCK_LOST');
  deny(f, x => {x.rights = null;}, 'RIGHTS_CLOCK_LOST');
  deny(f, x => {x.readers.push('SIM-PAYER-D');}, 'UNAUTHORISED_DISCLOSURE');
  deny(f, x => {x.deadlinesSelected = true;}, 'APPLICABILITY_UNDECIDED');
});
group('W07', 'Privacy draft §9; tabletop scenario 7', () => {
  const f = fixture('CASE-07'); safe(f);
  eq(new Date(Date.parse(ORIGINAL) + 72 * 60 * 60 * 1000).toISOString(),
    '2026-10-12T10:00:00.000Z', 'conditional fictional arithmetic, not reportability');
  deny(f, x => {x.breachConfirmed = true;}, 'UNASSESSED_BREACH');
  deny(f, x => {x.reportability = 'REPORTABLE';}, 'UNASSESSED_BREACH');
  deny(f, x => {x.dispatched.push('regulator-filing');}, 'EXTERNAL_ACTION');
  deny(f, x => {x.dispatched.push('guardian-fallback');}, 'EXTERNAL_ACTION');
});
group('W08', 'Safety draft §§4–5; tabletop scenario 8', () => {
  const f = fixture('CASE-08'), book = new Map(); f.priority = 'URGENT_UNRESOLVED';
  remember(book, f); remember(book, f); eq(book.size, 1, 'one local handoff record'); safe(f);
  deny(f, x => {x.appointments.push('Codex');}, 'INVENTED_APPOINTMENT');
  deny(f, x => {x.appointments.push('Founder-as-backup');}, 'INVENTED_APPOINTMENT');
  deny(f, x => {x.receivedAt = '2026-10-10T10:00:00.000Z';}, 'CLOCK_RESET');
  deny(f, x => {x.status = 'REVIEWED';}, 'FALSE_REVIEW');
  deny(f, x => {x.status = 'CLOSED';}, 'FALSE_CLOSURE');
  deny(f, x => {x.readers.push('shared-payer-contact');}, 'UNAUTHORISED_DISCLOSURE');
  eq(remember(book, f).status, 'BLOCKED', 'missing cover cannot discard intake');
});
group('R01', 'Privacy draft §6 recovery; separate from eight operational scenarios', () => {
  const f = fixture('RESTORE-01'); safe(f);
  deny(f, x => {x.restoreClaim = true; x.databaseVerified = true;}, 'INCOMPLETE_RECOVERY');
  deny(f, x => {x.restoreClaim = true; x.databaseVerified = true; x.objectsVerified = true;},
    'INCOMPLETE_RECOVERY');
  deny(f, x => {x.restoreClaim = true; x.databaseVerified = true; x.objectsVerified = true;
    x.deletionReconciled = true;}, 'INCOMPLETE_RECOVERY'); // lifecycle still unknown
  deny(f, x => {x.readers.push('erased-profile-reactivated');}, 'UNAUTHORISED_DISCLOSURE');
});
eq(groups.length, 9, 'eight scenario groups and one recovery group');
eq(new Set(groups.map(x => x.id)).size, 9, 'unique group names');
console.log(JSON.stringify({
  schema_version: 1, type: 'PRIVATE_FICTIONAL_MOCK_RULE_CHECK',
  passed_groups: groups.length, failed_groups: 0, assertions, groups,
  operational_scenarios: 'ALL_EIGHT_NOT_RUN', operational_rehearsals: 0,
  human_appointments: 0, production_imports: 0, external_calls: 0,
  real_person_records: 0, release_gate_acceptance: 0, founder_acceptance: false,
  qualification: 'Only this isolated mock checker is tested, not app enforcement, staffing, lawfulness or delivery.'
}, null, 2));

