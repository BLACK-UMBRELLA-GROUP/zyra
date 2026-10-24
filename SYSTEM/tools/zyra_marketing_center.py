#!/usr/bin/env python3
"""Local-only ZYRA Marketing Command Centre.

No social API, model API, credential, payment or public publishing capability is
present. The server binds to loopback and records exact Founder approvals for
manual publishing packs.  Account records are deliberately non-secret and live
social integrations remain disabled until the separate authentication gate is
approved and verified.
"""

from __future__ import annotations

import argparse
import fcntl
import hashlib
import json
import mimetypes
import os
import re
import sys
import tempfile
import threading
import webbrowser
from copy import deepcopy
from datetime import datetime, timezone
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlparse

PROJECT_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_DATA_DIR = PROJECT_ROOT / "SYSTEM" / "RESOURCES" / "MARKETING_COMMAND_CENTER"
WEB_DIR = Path(__file__).resolve().parent / "zyra_marketing_web"
SEED_PATH = WEB_DIR / "seed.json"
CONTENT_FIELDS = (
    "title", "pillar", "platform", "format", "objective", "hook", "body",
    "caption", "cta", "destination", "risk", "sources", "budgetGbp",
    "campaignId", "accountId", "assetRef", "assetSha256", "scheduledAt",
    "scheduleTimezone",
)
CAMPAIGN_FIELDS = ("title", "category", "audience", "pillar", "objective", "notes")
ACCOUNT_FIELDS = (
    "platform", "handle", "publicUrl", "loginIdentity", "owner",
    "accountStatus", "integrationStatus", "mfaStatus", "passkeyStatus",
    "recoveryStatus", "delegatedAccess", "businessStatus", "notes",
)
SECRET_FIELD_PATTERN = re.compile(
    r"password|passcode|token|secret|recovery.?code|totp|private.?key|api.?key",
    re.IGNORECASE,
)
PLATFORMS = (
    "Facebook", "Instagram", "Threads", "TikTok", "YouTube", "X",
    "Pinterest", "Reddit", "Snapchat",
)


def default_accounts() -> list[dict]:
    """Return a non-secret reconciliation row for each planned ZYRA channel."""
    return [
        {
            "id": f"SOC-{index:03d}",
            "platform": platform,
            "handle": "",
            "publicUrl": "",
            "loginIdentity": "",
            "owner": "Founder",
            "accountStatus": "NEEDS_RECONCILIATION",
            "integrationStatus": "NOT_CONNECTED",
            "mfaStatus": "NOT_RECORDED",
            "passkeyStatus": "NOT_RECORDED",
            "recoveryStatus": "NOT_RECORDED",
            "delegatedAccess": "NOT_RECORDED",
            "businessStatus": "NOT_RECORDED",
            "notes": "",
            "createdAt": now_iso(),
            "updatedAt": now_iso(),
        }
        for index, platform in enumerate(PLATFORMS, start=1)
    ]


def reject_secret_fields(payload: dict) -> None:
    for key, value in payload.items():
        if SECRET_FIELD_PATTERN.search(str(key)) and str(value or "").strip():
            raise StateError(
                "Secrets are prohibited here. Record only non-secret account and security status."
            )


def ensure_schema(state: dict) -> dict:
    """Upgrade older local state in memory without losing existing records."""
    state["version"] = max(int(state.get("version") or 1), 2)
    state.setdefault("intakeMode", "COLLECT_ONLY")
    state.setdefault("inspiration", [])
    state.setdefault("accounts", default_accounts())
    state.setdefault("campaigns", [])
    state.setdefault("calendarSettings", {
        "timezone": "Europe/London",
        "minimumIdeasPerDay": 1,
        "maximumIdeasPerDay": 3,
    })
    state.setdefault("connectionPolicy", {
        "liveConnectionsEnabled": False,
        "publishingEnabled": False,
        "communityReplyEnabled": False,
        "reason": "Authentication and encrypted secret storage must be approved and verified first.",
    })
    for item in state.get("content", []):
        for field in CONTENT_FIELDS:
            item.setdefault(field, [] if field == "sources" else "")
    if not state["campaigns"] and state.get("content"):
        for index, item in enumerate(state["content"], start=1):
            campaign_id = f"CMP-{index:03d}"
            state["campaigns"].append({
                "id": campaign_id,
                "title": item.get("title") or f"Campaign {index}",
                "category": "UNCLASSIFIED",
                "audience": "Both",
                "pillar": item.get("pillar", ""),
                "objective": item.get("objective", ""),
                "notes": "Migrated from the original single-post pipeline.",
                "status": "PLANNING",
                "createdAt": item.get("createdAt") or now_iso(),
                "updatedAt": item.get("updatedAt") or now_iso(),
            })
            item["campaignId"] = campaign_id
    return state


def now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def public_payload(item: dict) -> dict:
    return {key: item.get(key) for key in CONTENT_FIELDS}


def preview_hash(item: dict) -> str:
    encoded = json.dumps(public_payload(item), ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(encoded).hexdigest()


def brand_check(item: dict) -> dict:
    text = " ".join(str(item.get(key, "")) for key in ("title", "hook", "body", "caption", "cta"))
    issues: list[dict] = []
    rules = [
        (r"\bzyra\s+is\s+(?:a|the)\s+dating\s+app\b", "critical", "ZYRA must not be described as a dating app."),
        (r"\bguarantee(?:d|s)?\b|\bperfect match\b|\b100% compatible\b", "critical", "Outcome or compatibility guarantees are prohibited."),
        (r"\bavailable now\b|\bdownload now\b|\bjoin now\b|\bstart (?:your )?free trial\b", "critical", "The product is in private testing; public availability cannot be claimed."),
        (r"\bsee(?:s)? all (?:their )?messages\b|\bread(?:s|ing)? private messages\b", "critical", "Guardian visibility and private-message claims are inaccurate."),
        (r"\bAI\b", "warning", "Public copy uses ZYRA Intelligence, not AI."),
        (r"\bhalal[- ]certified\b|\bscholar[- ]approved\b", "critical", "Religious certification or scholarly endorsement needs named, verified authority."),
        (r"\bbest muslim\b|\bnumber one muslim\b", "warning", "Superlative market claims require evidence."),
    ]
    for pattern, severity, message in rules:
        if re.search(pattern, text, re.IGNORECASE):
            issues.append({"severity": severity, "message": message})
    sources = item.get("sources") or []
    if isinstance(sources, str):
        sources = [value.strip() for value in sources.splitlines() if value.strip()]
    if not sources:
        issues.append({"severity": "critical", "message": "At least one approved ZYRA source is required."})
    if item.get("pillar") in {"Product demonstrations", "Pre-launch progress and testing"} and not re.search(r"private test|testing|development preview", text, re.IGNORECASE):
        issues.append({"severity": "warning", "message": "Product/pre-launch content should state that ZYRA is in private testing or show an equivalent truthful label."})
    return {
        "passed": not any(issue["severity"] == "critical" for issue in issues),
        "issues": issues,
        "checkedAt": now_iso(),
    }


class StateError(ValueError):
    pass


class Store:
    def __init__(self, data_dir: Path = DEFAULT_DATA_DIR):
        self.data_dir = data_dir
        self.path = data_dir / "state.json"
        self.process_lock_path = data_dir / ".state.lock"
        self.lock = threading.RLock()
        self.data_dir.mkdir(parents=True, exist_ok=True)
        if not self.path.exists():
            seed = json.loads(SEED_PATH.read_text(encoding="utf-8"))
            with self.process_lock_path.open("a+") as lock_handle:
                fcntl.flock(lock_handle.fileno(), fcntl.LOCK_EX)
                if not self.path.exists():
                    self._write(seed)
                fcntl.flock(lock_handle.fileno(), fcntl.LOCK_UN)

    def _write(self, state: dict) -> None:
        state["updatedAt"] = now_iso()
        fd, temporary = tempfile.mkstemp(prefix="state.", suffix=".tmp", dir=self.data_dir)
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as handle:
                json.dump(state, handle, ensure_ascii=False, indent=2)
                handle.write("\n")
            os.replace(temporary, self.path)
        finally:
            if os.path.exists(temporary):
                os.unlink(temporary)

    def read(self) -> dict:
        with self.lock:
            with self.process_lock_path.open("a+") as lock_handle:
                fcntl.flock(lock_handle.fileno(), fcntl.LOCK_SH)
                state = ensure_schema(json.loads(self.path.read_text(encoding="utf-8")))
                fcntl.flock(lock_handle.fileno(), fcntl.LOCK_UN)
                return state

    def mutate(self, callback):
        with self.lock:
            with self.process_lock_path.open("a+") as lock_handle:
                fcntl.flock(lock_handle.fileno(), fcntl.LOCK_EX)
                state = ensure_schema(json.loads(self.path.read_text(encoding="utf-8")))
                result = callback(state)
                self._write(state)
                fcntl.flock(lock_handle.fileno(), fcntl.LOCK_UN)
                return deepcopy(result), deepcopy(state)

    @staticmethod
    def _next_id(state: dict, prefix: str, collection: str) -> str:
        numbers = []
        for value in state.get(collection, []):
            match = re.fullmatch(rf"{re.escape(prefix)}-(\d+)", str(value.get("id", "")))
            if match:
                numbers.append(int(match.group(1)))
        return f"{prefix}-{max(numbers, default=0) + 1:03d}"

    @staticmethod
    def _find(state: dict, item_id: str) -> dict:
        for item in state.get("content", []):
            if item.get("id") == item_id:
                return item
        raise StateError(f"Unknown content item: {item_id}")

    @staticmethod
    def _find_in(state: dict, collection: str, item_id: str) -> dict:
        for item in state.get(collection, []):
            if item.get("id") == item_id:
                return item
        raise StateError(f"Unknown {collection.rstrip('s')} item: {item_id}")

    @staticmethod
    def _validate_content_links(state: dict, item: dict, current_id: str = "") -> None:
        campaign_id = str(item.get("campaignId", "")).strip()
        account_id = str(item.get("accountId", "")).strip()
        if campaign_id:
            Store._find_in(state, "campaigns", campaign_id)
        if account_id:
            Store._find_in(state, "accounts", account_id)
        asset_hash = str(item.get("assetSha256", "")).strip()
        if asset_hash and not re.fullmatch(r"[a-fA-F0-9]{64}", asset_hash):
            raise StateError("Asset fingerprint must be a complete SHA-256 value or left blank.")
        scheduled_at = str(item.get("scheduledAt", "")).strip()
        if scheduled_at:
            day = scheduled_at[:10]
            idea_keys = set()
            for value in state.get("content", []):
                if value.get("id") == current_id or str(value.get("scheduledAt", ""))[:10] != day:
                    continue
                idea_keys.add(value.get("campaignId") or value.get("id"))
            idea_keys.add(campaign_id or current_id or "NEW")
            maximum = int(state.get("calendarSettings", {}).get("maximumIdeasPerDay", 3))
            if len(idea_keys) > maximum:
                raise StateError(
                    f"{day} already reaches the {maximum}-idea daily limit. Add a platform variant to an existing campaign or choose another day."
                )

    def add_content(self, payload: dict):
        def change(state):
            item = {key: payload.get(key, "") for key in CONTENT_FIELDS}
            item["id"] = self._next_id(state, "CNT", "content")
            item["status"] = "DRAFT"
            item["createdAt"] = item["updatedAt"] = now_iso()
            item["sources"] = payload.get("sources") or []
            item["brandCheck"] = None
            item["compliance"] = None
            item["approval"] = None
            item["publication"] = None
            self._validate_content_links(state, item)
            state.setdefault("content", []).append(item)
            state.setdefault("events", []).append({"at": now_iso(), "type": "CONTENT_CREATED", "itemId": item["id"]})
            return item
        return self.mutate(change)

    def update_content(self, payload: dict):
        def change(state):
            item = self._find(state, str(payload.get("id", "")))
            if item.get("status") in {"MANUALLY_PUBLISHED", "MEASURED"}:
                raise StateError("Published records are immutable; create a correction or new version.")
            before = preview_hash(item)
            for key in CONTENT_FIELDS:
                if key in payload:
                    item[key] = payload[key]
            self._validate_content_links(state, item, item["id"])
            after = preview_hash(item)
            if before != after:
                item["status"] = "DRAFT"
                item["brandCheck"] = None
                item["compliance"] = None
                item["approval"] = None
                state.setdefault("events", []).append({"at": now_iso(), "type": "APPROVAL_INVALIDATED_BY_EDIT", "itemId": item["id"]})
            item["updatedAt"] = now_iso()
            return item
        return self.mutate(change)

    def add_campaign(self, payload: dict):
        def change(state):
            item = {key: str(payload.get(key, "")).strip() for key in CAMPAIGN_FIELDS}
            if not item["title"] or not item["objective"]:
                raise StateError("A master idea needs a title and objective.")
            item.update({
                "id": self._next_id(state, "CMP", "campaigns"),
                "status": "PLANNING",
                "createdAt": now_iso(),
                "updatedAt": now_iso(),
            })
            state.setdefault("campaigns", []).append(item)
            state.setdefault("events", []).append({
                "at": now_iso(), "type": "CAMPAIGN_CREATED", "itemId": item["id"]
            })
            return item
        return self.mutate(change)

    def update_campaign(self, payload: dict):
        def change(state):
            item = self._find_in(state, "campaigns", str(payload.get("id", "")))
            for key in CAMPAIGN_FIELDS:
                if key in payload:
                    item[key] = str(payload[key]).strip()
            if not item.get("title") or not item.get("objective"):
                raise StateError("A master idea needs a title and objective.")
            item["updatedAt"] = now_iso()
            state.setdefault("events", []).append({
                "at": now_iso(), "type": "CAMPAIGN_UPDATED", "itemId": item["id"]
            })
            return item
        return self.mutate(change)

    def update_account(self, payload: dict):
        reject_secret_fields(payload)

        def change(state):
            item = self._find_in(state, "accounts", str(payload.get("id", "")))
            for key in ACCOUNT_FIELDS:
                if key in payload:
                    item[key] = str(payload[key]).strip()
            if item.get("platform") not in PLATFORMS:
                raise StateError("Use one of the governed ZYRA social platforms.")
            if item.get("integrationStatus") == "CONNECTED":
                raise StateError("Live connections are disabled until authentication and secret storage are approved.")
            item["updatedAt"] = now_iso()
            item["lastCheckedAt"] = now_iso()
            state.setdefault("events", []).append({
                "at": now_iso(), "type": "ACCOUNT_RECONCILED", "itemId": item["id"]
            })
            return item
        return self.mutate(change)

    def action(self, payload: dict):
        action = str(payload.get("action", ""))

        def change(state):
            item = self._find(state, str(payload.get("id", "")))
            status = item.get("status")
            event = action.upper()
            if action == "brand_check":
                item["brandCheck"] = brand_check(item)
                item["status"] = "BRAND_REVIEWED" if item["brandCheck"]["passed"] else "CORRECTION_REQUIRED"
            elif action == "compliance_review":
                if status != "BRAND_REVIEWED" or not (item.get("brandCheck") or {}).get("passed"):
                    raise StateError("Brand review must pass first.")
                item["compliance"] = {"status": "RECORDED_REVIEW", "at": now_iso(), "note": str(payload.get("note", ""))}
                item["status"] = "COMPLIANCE_REVIEWED"
            elif action == "budget_approve":
                if item.get("risk") != "spend" or float(item.get("budgetGbp") or 0) <= 0:
                    raise StateError("A positive budget is required for a spend-bearing item.")
                item["budgetApproval"] = {"status": "FOUNDER_APPROVED", "at": now_iso(), "amountGbp": float(item["budgetGbp"])}
            elif action == "submit_founder":
                required = "COMPLIANCE_REVIEWED" if item.get("risk") in {"sensitive", "spend"} else "BRAND_REVIEWED"
                if status != required:
                    raise StateError(f"This item requires {required} before Founder review.")
                if not item.get("campaignId") or not item.get("accountId"):
                    raise StateError("Assign the exact master idea and destination account before Founder review.")
                if item.get("risk") == "spend" and (item.get("budgetApproval") or {}).get("status") != "FOUNDER_APPROVED":
                    raise StateError("Spend requires a separate Founder budget approval.")
                item["status"] = "FOUNDER_REVIEW"
                item["reviewHash"] = preview_hash(item)
            elif action == "founder_approve":
                if status != "FOUNDER_REVIEW":
                    raise StateError("Only an item in Founder review can be approved.")
                current_hash = preview_hash(item)
                if current_hash != item.get("reviewHash"):
                    raise StateError("The preview changed after submission; review it again.")
                item["status"] = "APPROVED"
                item["approval"] = {
                    "decision": "APPROVED", "at": now_iso(),
                    "previewHash": current_hash, "actor": "Founder",
                }
            elif action == "founder_reject":
                if status != "FOUNDER_REVIEW":
                    raise StateError("Only an item in Founder review can be rejected.")
                item["status"] = "REJECTED"
                item["approval"] = {
                    "decision": "REJECTED", "at": now_iso(),
                    "note": str(payload.get("note", "")), "actor": "Founder",
                }
            elif action == "return_draft":
                if status in {"MANUALLY_PUBLISHED", "MEASURED"}:
                    raise StateError("Published records cannot return to draft.")
                item["status"] = "DRAFT"
                item["brandCheck"] = item["compliance"] = item["approval"] = None
            elif action == "mark_published":
                if status != "APPROVED":
                    raise StateError("Only an approved exact preview can be marked published.")
                item["status"] = "MANUALLY_PUBLISHED"
                url = str(payload.get("url", "")).strip()
                if not url.startswith(("https://", "http://")):
                    raise StateError("Record the complete public post URL after publishing.")
                item["publication"] = {"at": now_iso(), "url": url, "mode": "MANUAL"}
            elif action == "mark_measured":
                if status != "MANUALLY_PUBLISHED":
                    raise StateError("Only a manually published item can be marked measured.")
                if not any(metric.get("contentId") == item["id"] for metric in state.get("metrics", [])):
                    raise StateError("Add at least one performance record first.")
                item["status"] = "MEASURED"
            else:
                raise StateError(f"Unknown action: {action}")
            item["updatedAt"] = now_iso()
            state.setdefault("events", []).append({"at": now_iso(), "type": event, "itemId": item["id"], "status": item["status"]})
            return item
        return self.mutate(change)

    def add_research(self, payload: dict):
        def change(state):
            item = {"id": self._next_id(state, "RES", "research"), "createdAt": now_iso(), **payload}
            state.setdefault("research", []).append(item)
            return item
        return self.mutate(change)

    def add_inspiration(self, payload: dict):
        """Capture an inspiration link without fetching, analysing or using it."""
        def change(state):
            source_url = str(payload.get("sourceUrl", "")).strip()
            if not source_url.startswith(("https://", "http://")):
                raise StateError("A complete http(s) video URL is required.")
            canonical = source_url.rstrip("/").lower()
            duplicate = next(
                (
                    value.get("id")
                    for value in state.get("inspiration", [])
                    if str(value.get("sourceUrl", "")).rstrip("/").lower() == canonical
                ),
                None,
            )
            item = {
                "id": self._next_id(state, "VID", "inspiration"),
                "createdAt": now_iso(),
                "platform": str(payload.get("platform", "TikTok")),
                "sourceUrl": source_url,
                "note": str(payload.get("note", "")).strip(),
                "status": "DUPLICATE" if duplicate else "CAPTURED",
                "duplicateOf": duplicate,
                "analysis": None,
            }
            state.setdefault("inspiration", []).append(item)
            state.setdefault("events", []).append({
                "at": now_iso(),
                "type": "INSPIRATION_CAPTURED",
                "itemId": item["id"],
                "status": item["status"],
            })
            return item
        return self.mutate(change)

    def add_community(self, payload: dict):
        def change(state):
            category = str(payload.get("category", "routine"))
            human_only = category in {"safety", "complaint", "religious", "sensitive_matrimonial", "press_regulator"}
            item = {"id": self._next_id(state, "COM", "community"), "createdAt": now_iso(), **payload, "humanOnly": human_only, "status": "HUMAN_ESCALATION" if human_only else "DRAFT_REPLY"}
            state.setdefault("community", []).append(item)
            return item
        return self.mutate(change)

    def add_metric(self, payload: dict):
        def change(state):
            self._find(state, str(payload.get("contentId", "")))
            item = {"id": self._next_id(state, "MET", "metrics"), "recordedAt": now_iso(), **payload}
            state.setdefault("metrics", []).append(item)
            return item
        return self.mutate(change)


class Handler(BaseHTTPRequestHandler):
    store: Store

    def log_message(self, format, *args):
        sys.stderr.write("[marketing-centre] " + format % args + "\n")

    def _json(self, value, status=HTTPStatus.OK):
        body = json.dumps(value, ensure_ascii=False, indent=2).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.end_headers()
        self.wfile.write(body)

    def _read_json(self):
        length = int(self.headers.get("Content-Length", "0"))
        if length > 1_000_000:
            raise StateError("Request is too large.")
        return json.loads(self.rfile.read(length) or b"{}")

    def do_GET(self):
        path = unquote(urlparse(self.path).path)
        if path == "/api/state":
            return self._json(self.store.read())
        if path.startswith("/api/export/"):
            item_id = path.rsplit("/", 1)[-1]
            state = self.store.read()
            try:
                item = self.store._find(state, item_id)
            except StateError as error:
                return self._json({"ok": False, "error": str(error)}, HTTPStatus.NOT_FOUND)
            pack = {"content": public_payload(item), "status": item.get("status"), "approval": item.get("approval"), "previewHash": preview_hash(item), "instruction": "Manual publishing only. Reconfirm the exact preview before posting."}
            return self._json(pack)
        relative = "index.html" if path in {"", "/"} else path.lstrip("/")
        target = (WEB_DIR / relative).resolve()
        if WEB_DIR.resolve() not in target.parents and target != WEB_DIR.resolve():
            return self.send_error(HTTPStatus.FORBIDDEN)
        if not target.is_file():
            target = WEB_DIR / "index.html"
        body = target.read_bytes()
        mime = mimetypes.guess_type(target.name)[0] or "application/octet-stream"
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", mime + ("; charset=utf-8" if mime.startswith("text/") else ""))
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Security-Policy", "default-src 'self'; style-src 'self'; script-src 'self'; connect-src 'self'; img-src 'self' data:; base-uri 'none'; frame-ancestors 'none'")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("X-Frame-Options", "DENY")
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        path = urlparse(self.path).path
        try:
            payload = self._read_json()
            routes = {
                "/api/content/new": self.store.add_content,
                "/api/content/update": self.store.update_content,
                "/api/content/action": self.store.action,
                "/api/campaign/new": self.store.add_campaign,
                "/api/campaign/update": self.store.update_campaign,
                "/api/account/update": self.store.update_account,
                "/api/research/new": self.store.add_research,
                "/api/inspiration/new": self.store.add_inspiration,
                "/api/community/new": self.store.add_community,
                "/api/metrics/new": self.store.add_metric,
            }
            if path not in routes:
                return self._json({"ok": False, "error": "Unknown endpoint."}, HTTPStatus.NOT_FOUND)
            item, state = routes[path](payload)
            return self._json({"ok": True, "item": item, "state": state})
        except (StateError, ValueError, json.JSONDecodeError) as error:
            return self._json({"ok": False, "error": str(error)}, HTTPStatus.BAD_REQUEST)


def serve(host: str, port: int, data_dir: Path, open_browser: bool) -> None:
    Handler.store = Store(data_dir)
    server = ThreadingHTTPServer((host, port), Handler)
    url = f"http://{host}:{port}"
    print(f"ZYRA Marketing Command Centre: {url}")
    print(f"State: {Handler.store.path}")
    print("Local only. No social publishing or paid API is connected.")
    if open_browser:
        threading.Timer(0.35, lambda: webbrowser.open(url)).start()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


def main() -> None:
    parser = argparse.ArgumentParser(description="ZYRA Marketing Command Centre")
    parser.add_argument("command", choices=("serve", "check"), nargs="?", default="serve")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=4319)
    parser.add_argument("--data-dir", type=Path, default=DEFAULT_DATA_DIR)
    parser.add_argument("--open", action="store_true")
    args = parser.parse_args()
    if args.host not in {"127.0.0.1", "localhost"}:
        raise SystemExit("Refusing non-loopback bind. The command centre is local-only.")
    if args.command == "check":
        state = Store(args.data_dir).read()
        print(json.dumps({"ok": True, "version": state.get("version"), "content": len(state.get("content", [])), "agents": len(state.get("agents", []))}, indent=2))
        return
    serve(args.host, args.port, args.data_dir, args.open)


if __name__ == "__main__":
    main()
