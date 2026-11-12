// LOCK 29 V2 / DOC-ZYRA-0445 / OA-ZYRA-317.
const MAX_BYTES = 20 * 1024 * 1024;
const MAX_DURATION_MS = 10_500n;
const UUID = "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}";
const OBJECT_ID = new RegExp(`^${UUID}$`);
const VIDEO_PATH = new RegExp(`^${UUID}/${UUID}\\.(mp4|mov)$`);
const MP4_BRAND = /^(isom|iso[2-9]|mp4[12]|avc1|hvc1|hev1|M4V |MSNV|dash|qt  )$/;

type Refusal = "has_sound" | "too_long" | "not_a_video" | "too_large" | "not_allowed";
type Validation = { durationMs: number } | { reason: Refusal };
type Box = { type: string; data: number; end: number };
type Config = { url: string; anonKey: string; serviceKey: string };

function fourCC(view: DataView, at: number): string {
  return String.fromCharCode(
    view.getUint8(at), view.getUint8(at + 1),
    view.getUint8(at + 2), view.getUint8(at + 3),
  );
}

function* boxes(view: DataView, start: number, end: number): Generator<Box> {
  while (start < end) {
    if (end - start < 8) throw new RangeError("truncated box");
    const type = fourCC(view, start + 4);
    const size32 = view.getUint32(start);
    let headerSize = 8;
    let size = size32 === 0 ? end - start : size32;
    if (size32 === 1) {
      headerSize = 16;
      if (end - start < headerSize) throw new RangeError("truncated extended box");
      const extended = view.getBigUint64(start + 8);
      if (extended > BigInt(end - start)) throw new RangeError("oversized box");
      size = Number(extended);
    }
    if (type === "uuid") headerSize += 16;
    if (size < headerSize || size > end - start) throw new RangeError("invalid box size");
    yield { type, data: start + headerSize, end: start + size };
    start += size;
  }
}

function onlyBox(view: DataView, parent: Box, type: string): Box {
  let match: Box | undefined;
  for (const child of boxes(view, parent.data, parent.end)) {
    if (child.type !== type) continue;
    if (match) throw new RangeError("duplicate box");
    match = child;
  }
  if (!match) throw new RangeError("missing box");
  return match;
}

function validBrand(view: DataView, box: Box): boolean {
  const length = box.end - box.data;
  if (length < 8 || length % 4 !== 0) return false;
  if (MP4_BRAND.test(fourCC(view, box.data))) return true;
  for (let at = box.data + 8; at < box.end; at += 4) {
    if (MP4_BRAND.test(fourCC(view, at))) return true;
  }
  return false;
}

export function validateVideo(bytes: Uint8Array): Validation {
  if (bytes.byteLength > MAX_BYTES) return { reason: "too_large" };
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  try {
    let fileType: Box | undefined;
    let movie: Box | undefined;
    let hasMediaData = false;
    for (const box of boxes(view, 0, bytes.byteLength)) {
      if (box.type === "ftyp") {
        if (fileType) return { reason: "not_a_video" };
        fileType = box;
      }
      if (box.type === "moov") {
        if (movie) return { reason: "not_a_video" };
        movie = box;
      }
      if (box.type === "mdat" && box.end > box.data) hasMediaData = true;
    }
    if (!fileType || !movie || !hasMediaData || !validBrand(view, fileType)) {
      return { reason: "not_a_video" };
    }

    const header = onlyBox(view, movie, "mvhd");
    let videoTracks = 0;
    for (const track of boxes(view, movie.data, movie.end)) {
      if (track.type !== "trak") continue;
      const media = onlyBox(view, track, "mdia");
      const handler = onlyBox(view, media, "hdlr");
      if (handler.end - handler.data < 24 || view.getUint8(handler.data) !== 0) {
        return { reason: "not_a_video" };
      }
      const type = fourCC(view, handler.data + 8);
      if (type === "soun") return { reason: "has_sound" };
      if (type === "vide") videoTracks++;
    }
    if (videoTracks !== 1 || header.end === header.data) return { reason: "not_a_video" };

    const version = view.getUint8(header.data);
    if (version > 1 || header.end - header.data < (version === 0 ? 100 : 112)) {
      return { reason: "not_a_video" };
    }
    const at = header.data + (version === 0 ? 12 : 20);
    const timescale = BigInt(view.getUint32(at));
    const duration = version === 0 ? BigInt(view.getUint32(at + 4)) : view.getBigUint64(at + 4);
    if (timescale === 0n || duration === 0n) return { reason: "not_a_video" };
    const scaled = duration * 1000n;
    if (scaled > MAX_DURATION_MS * timescale) return { reason: "too_long" };
    // Round up so a positive duration below 1 ms still fits the DB constraint.
    return { durationMs: Number((scaled + timescale - 1n) / timescale) };
  } catch (error) {
    if (error instanceof RangeError) return { reason: "not_a_video" };
    throw error;
  }
}

export function ownsVideoPath(path: unknown, user: string): path is string {
  return typeof path === "string" && VIDEO_PATH.test(path) && path.startsWith(`${user}/`);
}

async function readVideo(response: Response): Promise<Validation> {
  const body = response.body;
  if (!body) return { reason: "not_a_video" };
  if (Number(response.headers.get("content-length")) > MAX_BYTES) {
    await body.cancel();
    return { reason: "too_large" };
  }
  const reader = body.getReader();
  const chunks: Uint8Array[] = [];
  let size = 0;
  while (true) {
    const chunk = await reader.read();
    if (chunk.done) break;
    size += chunk.value.byteLength;
    if (size > MAX_BYTES) {
      await reader.cancel();
      return { reason: "too_large" };
    }
    chunks.push(chunk.value);
  }
  const bytes = new Uint8Array(size);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return validateVideo(bytes);
}

function json(body: object, status = 200): Response {
  return Response.json(body, { status, headers: { "Cache-Control": "no-store" } });
}

function refuse(reason: Refusal, status = 200): Response {
  return json({ ok: false, reason }, status);
}

function unavailable(): Response {
  return json({ error: "temporarily_unavailable" }, 503);
}

async function storageObjectMissing(response: Response): Promise<boolean> {
  if (response.status === 404) return true;
  if (response.status !== 400) return false;
  const body = await response.json().catch(() => null);
  return String(body?.statusCode) === "404" && body?.code === "NoSuchKey";
}

export function createSubmitHandler(config: Config, request = fetch) {
  const url = config.url.replace(/\/$/, "");
  const serviceHeaders = {
    apikey: config.serviceKey,
    Authorization: `Bearer ${config.serviceKey}`,
    "Content-Type": "application/json",
  };
  const send = (path: string, init: RequestInit) =>
    request(`${url}${path}`, { ...init, redirect: "error" });

  return async (incoming: Request): Promise<Response> => {
    if (incoming.method !== "POST") return refuse("not_allowed", 405);
    const authorization = incoming.headers.get("Authorization");
    if (!authorization || !/^Bearer \S+$/i.test(authorization)) {
      return refuse("not_allowed", 401);
    }

    try {
      const memberHeaders = { apikey: config.anonKey, Authorization: authorization };
      const auth = await send("/auth/v1/user", { headers: memberHeaders });
      if (auth.status === 401 || auth.status === 403) return refuse("not_allowed", 401);
      if (!auth.ok) return unavailable();
      const user = (await auth.json()).id;
      if (typeof user !== "string" || !OBJECT_ID.test(user)) return refuse("not_allowed", 401);

      const body = await incoming.json().catch(() => null);
      const path = body?.path;
      if (!ownsVideoPath(path, user)) return refuse("not_allowed");

      const key = `profile-videos/${path}`;
      const info = await send(`/storage/v1/object/info/authenticated/${key}`, {
        headers: serviceHeaders,
      });
      if (!info.ok) {
        return await storageObjectMissing(info) ? refuse("not_a_video") : unavailable();
      }
      const object = await info.json();
      if (typeof object.id !== "string" || !OBJECT_ID.test(object.id) ||
          typeof object.version !== "string" || !OBJECT_ID.test(object.version)) {
        return unavailable();
      }

      const version = `?versionId=${encodeURIComponent(object.version)}`;
      const discard = async (reason: Refusal): Promise<Response> => {
        const response = await send(`/storage/v1/object/${key}${version}`, {
          method: "DELETE",
          headers: serviceHeaders,
        });
        return response.ok || await storageObjectMissing(response) ? refuse(reason) : unavailable();
      };

      if (typeof object.size === "number" && object.size > MAX_BYTES) return await discard("too_large");
      const download = await send(`/storage/v1/object/authenticated/${key}${version}`, {
        headers: serviceHeaders,
      });
      if (!download.ok) {
        return await storageObjectMissing(download) ? refuse("not_a_video") : unavailable();
      }
      const validation = await readVideo(download);
      if ("reason" in validation) return await discard(validation.reason);

      const record = await send("/rest/v1/rpc/zyra_record_profile_video", {
        method: "POST",
        headers: serviceHeaders,
        body: JSON.stringify({
          p_user: user,
          p_path: path,
          p_duration_ms: validation.durationMs,
          p_object_id: object.id,
        }),
      });
      if (record.ok) return json({ ok: true, status: "pending" });

      const error = await record.json();
      if (error.message === "profile_video_upload_changed" ||
          error.message === "profile_video_path_used") return refuse("not_a_video");
      if (error.message !== "profile_video_not_allowed") return unavailable();

      // A delayed retry after downgrade must not remove a previously checked clip.
      const own = await send("/rest/v1/rpc/zyra_my_profile_video", {
        method: "POST",
        headers: { ...memberHeaders, "Content-Type": "application/json" },
        body: "{}",
      });
      if (!own.ok) return unavailable();
      const [current] = await own.json();
      if (current?.storage_path === path) return refuse("not_allowed");
      return await discard("not_allowed");
    } catch {
      return unavailable();
    }
  };
}

if (import.meta.main) {
  const url = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !anonKey || !serviceKey) throw new Error("Missing Supabase function configuration");
  Deno.serve(createSubmitHandler({ url, anonKey, serviceKey }));
}
