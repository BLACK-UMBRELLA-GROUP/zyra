// LOCK 29 V2 / DOC-ZYRA-0445 / OA-ZYRA-317. Synthetic boxes only.
import { createSubmitHandler, ownsVideoPath, validateVideo } from "./index.ts";

const user = "12345678-1234-4567-8901-123456789012";
const other = "87654321-1234-4567-8901-123456789012";
const objectId = "12345678-1234-4567-8901-123456789099";
const version = "12345678-1234-4567-8901-123456789098";
const path = `${user}/${other}.mp4`;
const encoder = new TextEncoder();

function equal(actual: unknown, expected: unknown): void {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(`Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

function concat(...parts: Uint8Array[]): Uint8Array {
  const out = new Uint8Array(parts.reduce((sum, part) => sum + part.length, 0));
  let offset = 0;
  for (const part of parts) {
    out.set(part, offset);
    offset += part.length;
  }
  return out;
}

function box(type: string, ...parts: Uint8Array[]): Uint8Array {
  const header = new Uint8Array(8);
  new DataView(header.buffer).setUint32(0, 8 + parts.reduce((sum, part) => sum + part.length, 0));
  header.set(encoder.encode(type), 4);
  return concat(header, ...parts);
}

function fixture(
  duration: number | bigint,
  tracks: string[] = ["vide"],
  brand = "isom",
  timescale = 1000,
): Uint8Array {
  const header = new Uint8Array(typeof duration === "number" ? 100 : 112);
  const view = new DataView(header.buffer);
  if (typeof duration === "number") {
    view.setUint32(12, timescale);
    view.setUint32(16, duration);
  } else {
    view.setUint8(0, 1);
    view.setUint32(20, timescale);
    view.setBigUint64(24, duration);
  }
  return concat(
    box("ftyp", encoder.encode(brand), new Uint8Array(4)),
    box("moov", box("mvhd", header), ...tracks.map((type) => {
      const handler = new Uint8Array(24);
      handler.set(encoder.encode(type), 8);
      return box("trak", box("mdia", box("hdlr", handler)));
    })),
    box("mdat", new Uint8Array([1])),
  );
}

Deno.test("video-only 8 s MP4 and QuickTime pass", () => {
  equal(validateVideo(fixture(8000)), { durationMs: 8000 });
  equal(validateVideo(fixture(8000, ["vide", "tmcd"], "qt  ")), { durationMs: 8000 });
});

Deno.test("audio track is refused even alongside video", () => {
  equal(validateVideo(fixture(8000, ["vide", "soun"])), { reason: "has_sound" });
});

Deno.test("duration handles both header versions and applies exact encoder allowance", () => {
  equal(validateVideo(fixture(12000)), { reason: "too_long" });
  equal(validateVideo(fixture(10500n)), { durationMs: 10500 });
  equal(validateVideo(fixture(105001n, ["vide"], "isom", 10000)), { reason: "too_long" });
  equal(validateVideo(fixture(1, ["vide"], "isom", 10000)), { durationMs: 1 });
  equal(validateVideo(fixture(8000, ["vide"], "isom", 0)), { reason: "not_a_video" });
});

Deno.test("missing or duplicate video, unsupported container and garbage are refused", () => {
  equal(validateVideo(fixture(8000, ["text"])), { reason: "not_a_video" });
  equal(validateVideo(fixture(8000, ["vide", "vide"])), { reason: "not_a_video" });
  equal(validateVideo(fixture(8000, ["vide"], "heic")), { reason: "not_a_video" });
  equal(validateVideo(encoder.encode("garbage")), { reason: "not_a_video" });
  equal(validateVideo(fixture(8000).slice(0, -1)), { reason: "not_a_video" });
  equal(validateVideo(new Uint8Array(20 * 1024 * 1024 + 1)), { reason: "too_large" });
});

Deno.test("only a fresh-shaped path in the authenticated member's folder is accepted", () => {
  equal(ownsVideoPath(path, user), true);
  equal(ownsVideoPath(path, other), false);
  equal(ownsVideoPath(`${user}/../${other}.mp4`, user), false);
  equal(ownsVideoPath(`${user}/${other}.mp4%2f`, user), false);
});

function submit(uploadPath: string): Request {
  return new Request("https://edge.example.test", {
    method: "POST",
    headers: { Authorization: "Bearer fixture-jwt" },
    body: JSON.stringify({ path: uploadPath }),
  });
}

function mock(
  bytes: Uint8Array,
  options: {
    paid?: boolean;
    recordError?: string;
    recordResult?: () => Response | Promise<Response>;
    ownerRead?: () => Promise<Response>;
    cleanupFailure?: boolean;
    missing?: boolean;
  } = {},
) {
  const calls: string[] = [];
  const config = { url: "https://project.example.test", anonKey: "fixture-public", serviceKey: "fixture-service" };
  const request: typeof fetch = async (input, init) => {
    const url = new URL(String(input));
    const method = init?.method ?? "GET";
    const headers = new Headers(init?.headers);
    calls.push(`${method} ${url.pathname}`);
    if (url.pathname === "/auth/v1/user") {
      equal(headers.get("authorization"), "Bearer fixture-jwt");
      return Response.json({ id: user });
    }
    if (url.pathname === "/rest/v1/rpc/zyra_my_paid_access") {
      equal(headers.get("authorization"), "Bearer fixture-jwt");
      equal(headers.get("apikey"), "fixture-public");
      equal(method, "POST");
      equal(JSON.parse(String(init?.body)), { p_role: "seeker" });
      return Response.json(options.paid ?? true);
    }
    if (url.pathname === "/rest/v1/rpc/zyra_my_profile_video" && options.ownerRead) {
      return await options.ownerRead();
    }
    equal(headers.get("authorization"), "Bearer fixture-service");
    if (url.pathname.includes("/info/authenticated/")) {
      return options.missing
        ? Response.json({ statusCode: "404", code: "NoSuchKey" }, { status: 400 })
        : Response.json({ id: objectId, version });
    }
    if (url.pathname === "/rest/v1/rpc/zyra_record_profile_video") {
      equal(JSON.parse(String(init?.body)), {
        p_user: user, p_path: path, p_duration_ms: 8000, p_object_id: objectId,
      });
      if (options.recordResult) return await options.recordResult();
      return options.recordError
        ? Response.json({ message: options.recordError }, { status: 403 })
        : Response.json(objectId);
    }
    equal(url.searchParams.get("versionId"), version);
    if (method === "DELETE") return new Response(null, { status: options.cleanupFailure ? 500 : 204 });
    return new Response(new Uint8Array(bytes).buffer);
  };
  return { calls, handler: createSubmitHandler(config, request) };
}

Deno.test("wrong folder never touches Storage", async () => {
  const { calls, handler } = mock(fixture(8000));
  const response = await handler(submit(`${other}/${other}.mp4`));
  equal(await response.json(), { ok: false, reason: "not_allowed" });
  equal(calls, ["GET /auth/v1/user"]);
});

Deno.test("acceptance binds the reviewed upload identity and records pending", async () => {
  const { calls, handler } = mock(fixture(8000));
  equal(await (await handler(submit(path))).json(), { ok: true, status: "pending" });
  equal(calls.length, 5);
  equal(calls.at(-1), "POST /rest/v1/rpc/zyra_record_profile_video");
});

Deno.test("audio is deleted before refusal, with no record call", async () => {
  const { calls, handler } = mock(fixture(8000, ["vide", "soun"]));
  equal(await (await handler(submit(path))).json(), { ok: false, reason: "has_sound" });
  equal(calls.length, 5);
  equal(calls.at(-1), `DELETE /storage/v1/object/profile-videos/${path}`);
});

Deno.test("cleanup failure for refused media is retryable", async () => {
  const failed = mock(fixture(8000, ["vide", "soun"]), { cleanupFailure: true });
  equal((await failed.handler(submit(path))).status, 503);
});

Deno.test("a currently ineligible member is refused before Storage is accessed", async () => {
  const { calls, handler } = mock(fixture(8000), { paid: false });
  equal(await (await handler(submit(path))).json(), { ok: false, reason: "not_allowed" });
  equal(calls, ["GET /auth/v1/user", "POST /rest/v1/rpc/zyra_my_paid_access"]);
});

function signal() {
  let reach!: () => void;
  const reached = new Promise<void>((resolve) => { reach = resolve; });
  return { reach, reached };
}

Deno.test("a late role refusal cannot delete the version a concurrent retry records", async () => {
  const deniedRecord = signal();
  const ownerRead = signal();
  const allowRetry = signal();
  const retryRecorded = signal();
  let recordAttempts = 0;
  const { calls, handler } = mock(fixture(8000), {
    recordResult: async () => {
      if (++recordAttempts === 1) {
        deniedRecord.reach();
        return Response.json({ message: "profile_video_not_allowed" }, { status: 403 });
      }
      await allowRetry.reached;
      retryRecorded.reach();
      return Response.json(objectId);
    },
    ownerRead: async () => {
      // Model the old check-then-delete path reading an empty owner slot
      // before the retry commits and getting that stale result afterwards.
      ownerRead.reach();
      await retryRecorded.reached;
      return Response.json([]);
    },
  });

  const denied = handler(submit(path));
  await deniedRecord.reached;
  const retry = handler(submit(path));
  await Promise.race([denied, ownerRead.reached]);
  allowRetry.reach();

  equal(await (await retry).json(), { ok: true, status: "pending" });
  equal(await (await denied).json(), { ok: false, reason: "not_allowed" });
  equal(recordAttempts, 2);
  equal(calls.filter((call) => call.startsWith("DELETE ")), []);
});

Deno.test("Storage's missing-object envelope is a content refusal", async () => {
  const missing = mock(fixture(8000), { missing: true });
  equal(await (await missing.handler(submit(path))).json(), { ok: false, reason: "not_a_video" });
  equal(missing.calls.length, 3);
});

Deno.test("a substituted object fails without removing the current upload", async () => {
  const stale = mock(fixture(8000), { recordError: "profile_video_upload_changed" });
  equal(await (await stale.handler(submit(path))).json(), { ok: false, reason: "not_a_video" });
  equal(stale.calls.at(-1), "POST /rest/v1/rpc/zyra_record_profile_video");
});
