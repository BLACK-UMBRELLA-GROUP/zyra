import { createCleanupHandler } from "./index.ts";

const url = "https://example.invalid";
const serviceKey = "test-only-service-authorization";
const serviceAuthorization = `Bearer ${serviceKey}`;

function assertEqual(actual: unknown, expected: unknown): void {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(`expected ${JSON.stringify(expected)}, received ${JSON.stringify(actual)}`);
  }
}

function invocation(authorization = serviceAuthorization, method = "POST") {
  return new Request(url, { method, headers: { Authorization: authorization } });
}

Deno.test("cleanup is callable only with the exact service authorization", async () => {
  let calls = 0;
  const handler = createCleanupHandler({ url, serviceKey }, async () => {
    calls++;
    return Response.json([]);
  });
  assertEqual((await handler(invocation("Bearer member"))).status, 401);
  assertEqual((await handler(invocation(serviceAuthorization, "GET"))).status, 405);
  assertEqual(calls, 0);
  assertEqual((await handler(invocation())).status, 200);
  assertEqual(calls, 1);
});

Deno.test("cleanup deletes only claimed exact object names and treats missing as success", async () => {
  const path = "uid/display original.jpg";
  const calls: unknown[] = [];
  const handler = createCleanupHandler({ url, serviceKey }, async (input, init) => {
    const route = new URL(String(input)).pathname;
    const body = JSON.parse(String(init?.body));
    assertEqual(new Headers(init?.headers).get("Authorization"), serviceAuthorization);
    calls.push([route, init?.method, body]);
    if (route.endsWith("zyra_claim_photo_object_deletions")) {
      return Response.json([{ bucket: "profile-photos", path, attempts: 1 }]);
    }
    if (route.startsWith("/storage/v1/")) return Response.json([]);
    return new Response(null, { status: 204 });
  });
  assertEqual(await (await handler(invocation())).json(), { deleted: 1, failed: 0 });
  assertEqual(calls, [
    ["/rest/v1/rpc/zyra_claim_photo_object_deletions", "POST", {}],
    ["/storage/v1/object/profile-photos", "DELETE", { prefixes: [path] }],
    ["/rest/v1/rpc/zyra_finish_photo_object_deletion", "POST", {
      p_bucket: "profile-photos",
      p_path: path,
      p_attempt: 1,
      p_error: null,
    }],
  ]);
});

Deno.test("cleanup persists Storage errors for the active attempt", async () => {
  const reports: unknown[] = [];
  const handler = createCleanupHandler({ url, serviceKey }, async (input, init) => {
    const route = new URL(String(input)).pathname;
    if (route.endsWith("zyra_claim_photo_object_deletions")) {
      return Response.json([
        { bucket: "profile-photo-sources", path: "uid/source-a.jpg", attempts: 2 },
        { bucket: "profile-photos", path: "uid/display-b.jpg", attempts: 7 },
      ]);
    }
    if (route.endsWith("/profile-photo-sources")) return new Response(null, { status: 500 });
    if (route.endsWith("/profile-photos")) throw new TypeError("network");
    reports.push(JSON.parse(String(init?.body)));
    return new Response(null, { status: 204 });
  });
  assertEqual(await (await handler(invocation())).json(), { deleted: 0, failed: 2 });
  assertEqual(reports, [
    { p_bucket: "profile-photo-sources", p_path: "uid/source-a.jpg", p_attempt: 2, p_error: "storage_http_500" },
    { p_bucket: "profile-photos", p_path: "uid/display-b.jpg", p_attempt: 7, p_error: "storage_unavailable" },
  ]);
});

Deno.test("cleanup reports unavailable when it cannot persist completion", async () => {
  const handler = createCleanupHandler({ url, serviceKey }, async (input) => {
    const route = new URL(String(input)).pathname;
    if (route.endsWith("zyra_claim_photo_object_deletions")) {
      return Response.json([{ bucket: "profile-photos", path: "uid/photo.jpg", attempts: 1 }]);
    }
    if (route.startsWith("/storage/v1/")) return Response.json([]);
    return new Response(null, { status: 500 });
  });
  assertEqual((await handler(invocation())).status, 503);
});
