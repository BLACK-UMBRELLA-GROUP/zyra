type Config = { url: string; serviceKey: string };
type Claim = { bucket: string; path: string; attempts: number };

const MAX_DELETIONS_PER_REQUEST = 12;
const BUCKETS = new Set(["profile-photos", "profile-photo-sources"]);

export function createCleanupHandler(config: Config, request = fetch) {
  const url = config.url.replace(/\/$/, "");
  const serviceAuthorization = `Bearer ${config.serviceKey}`;
  const send = (path: string, method: string, payload: unknown) =>
    request(`${url}${path}`, {
      method,
      headers: {
        apikey: config.serviceKey,
        Authorization: serviceAuthorization,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
      redirect: "error",
      signal: AbortSignal.timeout(5000),
    });

  return async (incoming: Request): Promise<Response> => {
    if (incoming.method !== "POST") return new Response(null, { status: 405 });
    if (!config.serviceKey || incoming.headers.get("Authorization") !== serviceAuthorization) {
      return new Response(null, { status: 401 });
    }

    try {
      let deleted = 0;
      let failed = 0;

      for (let index = 0; index < MAX_DELETIONS_PER_REQUEST; index++) {
        const response = await send("/rest/v1/rpc/zyra_claim_photo_object_deletions", "POST", {});
        if (!response.ok) return new Response(null, { status: 503 });
        const claims: Claim[] = await response.json();
        if (!Array.isArray(claims) || claims.length > 1) {
          return new Response(null, { status: 503 });
        }
        if (claims.length === 0) break;
        const { bucket, path, attempts } = claims[0];
        if (!BUCKETS.has(bucket)) return new Response(null, { status: 503 });
        let error: string | null = null;
        try {
          // The bulk endpoint takes exact object names in its JSON body.
          // A missing name is an empty successful removal, including retries.
          const removal = await send(`/storage/v1/object/${bucket}`, "DELETE", { prefixes: [path] });
          if (!removal.ok) error = `storage_http_${removal.status}`;
        } catch {
          error = "storage_unavailable";
        }

        const finish = await send("/rest/v1/rpc/zyra_finish_photo_object_deletion", "POST", {
          p_bucket: bucket,
          p_path: path,
          p_attempt: attempts,
          p_error: error,
        });
        if (!finish.ok) return new Response(null, { status: 503 });
        if (error === null) deleted++;
        else failed++;
      }
      return Response.json({ deleted, failed });
    } catch {
      return new Response(null, { status: 503 });
    }
  };
}

if (import.meta.main) {
  const url = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceKey) throw new Error("Photo cleanup service configuration unavailable");
  Deno.serve(createCleanupHandler({ url, serviceKey }));
}
