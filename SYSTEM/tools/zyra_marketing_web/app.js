const $ = (selector, root = document) => root.querySelector(selector);
const $$ = (selector, root = document) => [...root.querySelectorAll(selector)];
const create = (tag, className, text) => {
  const element = document.createElement(tag);
  if (className) element.className = className;
  if (text !== undefined) element.textContent = text;
  return element;
};

const API_ROOT = window.location.pathname.startsWith("/marketing") ? "/marketing" : "";

let state;
let activeFilter = "ALL";

async function api(path, payload) {
  const response = await fetch(`${API_ROOT}${path}`, payload ? { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(payload) } : {});
  const data = await response.json();
  if (!response.ok || data.ok === false) throw new Error(data.error || "The action could not be completed.");
  if (data.state) state = data.state;
  return data;
}

function toast(message, error = false) {
  const element = $("#toast");
  element.textContent = message;
  element.classList.toggle("error", error);
  element.classList.add("show");
  window.clearTimeout(toast.timer);
  toast.timer = window.setTimeout(() => element.classList.remove("show"), 2800);
}

function showView(name) {
  $$(".view").forEach((view) => view.classList.toggle("active", view.id === `view-${name}`));
  $$(".nav-item").forEach((button) => button.classList.toggle("active", button.dataset.view === name));
  window.scrollTo({ top: 0, behavior: "smooth" });
}

function chip(text, gold = false) {
  return create("span", `chip${gold ? " gold" : ""}`, text);
}

function renderStats() {
  const labels = [
    ["Draft work", ["DRAFT", "BRAND_REVIEWED", "COMPLIANCE_REVIEWED", "CORRECTION_REQUIRED"]],
    ["Founder review", ["FOUNDER_REVIEW"]],
    ["Approved", ["APPROVED"]],
    ["Published", ["MANUALLY_PUBLISHED", "MEASURED"]],
  ];
  const target = $("#status-stats");
  target.replaceChildren(...labels.map(([label, statuses]) => {
    const card = create("article", "stat");
    card.append(create("b", "", String(state.content.filter((item) => statuses.includes(item.status)).length)), create("span", "", label));
    return card;
  }));
}

function renderAgents() {
  const target = $("#agent-grid");
  target.replaceChildren(...state.agents.map((agent, index) => {
    const card = create("article", "agent-card");
    card.append(create("div", "agent-number", String(index + 1).padStart(2, "0")), create("h3", "", agent.name), create("p", "", agent.role));
    card.append(create("span", `status ${agent.status.toLowerCase()}`, agent.status.replaceAll("_", " ")));
    return card;
  }));
}

function accountLabel(account) {
  if (!account) return "Unassigned account";
  return `${account.platform}${account.handle ? ` · ${account.handle}` : ""}`;
}

function openAccountEditor(account) {
  const form = $("#account-form");
  form.reset();
  $("#account-form-title").textContent = account.platform;
  for (const name of ["id", "platform", "handle", "publicUrl", "loginIdentity", "owner", "accountStatus", "integrationStatus", "mfaStatus", "passkeyStatus", "recoveryStatus", "delegatedAccess", "businessStatus", "notes"]) {
    if (form.elements[name]) form.elements[name].value = account[name] ?? "";
  }
  $("#account-dialog").showModal();
}

function renderAccounts() {
  const accounts = state.accounts || [];
  const active = accounts.filter((item) => item.accountStatus === "ACTIVE").length;
  const secured = accounts.filter((item) => item.mfaStatus === "TESTED" && item.recoveryStatus === "TESTED").length;
  const reconciled = accounts.filter((item) => item.accountStatus !== "NEEDS_RECONCILIATION").length;
  $("#account-summary").replaceChildren(
    ...[[reconciled, "Reconciled"], [active, "Active"], [secured, "MFA + recovery tested"], [0, "Live AIOS connections"]].map(([value, label]) => {
      const card = create("article", "stat");
      card.append(create("b", "", String(value)), create("span", "", label));
      return card;
    }),
  );
  $("#account-grid").replaceChildren(...accounts.map((account) => {
    const card = create("article", "account-card");
    const top = create("div", "content-top");
    const title = create("div");
    title.append(create("p", "eyebrow", account.id), create("h3", "", account.platform));
    top.append(title, chip(statusLabel(account.accountStatus), account.accountStatus === "ACTIVE"));
    card.append(top);
    if (account.handle) card.append(create("p", "account-handle", account.handle));
    const security = create("div", "security-grid");
    security.append(
      chip(`MFA · ${statusLabel(account.mfaStatus)}`, account.mfaStatus === "TESTED"),
      chip(`Recovery · ${statusLabel(account.recoveryStatus)}`, account.recoveryStatus === "TESTED"),
      chip(`Passkey · ${statusLabel(account.passkeyStatus)}`, account.passkeyStatus === "TESTED"),
      chip(`AIOS · ${statusLabel(account.integrationStatus)}`),
    );
    card.append(security);
    const details = create("p", "content-summary", account.loginIdentity ? `Login identity: ${account.loginIdentity}` : "Login identity not reconciled");
    card.append(details);
    const edit = create("button", "button small secondary", "Review account");
    edit.type = "button";
    edit.addEventListener("click", () => openAccountEditor(account));
    card.append(edit);
    return card;
  }));
}

function campaignVariants(campaignId) {
  return state.content.filter((item) => item.campaignId === campaignId);
}

function openCampaignEditor(campaign = null) {
  const form = $("#campaign-form");
  form.reset();
  for (const name of ["id", "title", "category", "audience", "pillar", "objective", "notes"]) {
    if (campaign && form.elements[name]) form.elements[name].value = campaign[name] ?? "";
  }
  form.scrollIntoView({ behavior: "smooth", block: "start" });
}

function renderCampaigns() {
  const cards = (state.campaigns || []).map((campaign) => {
    const variants = campaignVariants(campaign.id);
    const card = create("article", "memory-card campaign-card");
    card.append(create("p", "eyebrow", `${campaign.id} · ${campaign.category}`), create("h3", "", campaign.title), create("p", "", campaign.objective));
    const meta = create("div", "content-meta");
    meta.append(chip(campaign.audience), chip(campaign.pillar), chip(`${variants.length} variant${variants.length === 1 ? "" : "s"}`, true));
    card.append(meta);
    if (variants.length) {
      const list = create("div", "variant-list");
      variants.forEach((variant) => list.append(create("div", "variant-row", `${variant.platform} · ${variant.format} · ${statusLabel(variant.status)}`)));
      card.append(list);
    }
    const actions = create("div", "content-actions");
    const edit = create("button", "button small secondary", "Edit idea");
    edit.type = "button"; edit.addEventListener("click", () => openCampaignEditor(campaign));
    const add = create("button", "button small gold", "Add platform variant");
    add.type = "button"; add.addEventListener("click", () => openEditor({ campaignId: campaign.id, pillar: campaign.pillar, objective: campaign.objective }));
    actions.append(edit, add); card.append(actions);
    return card;
  });
  $("#campaign-list").replaceChildren(...(cards.length ? cards : [create("div", "empty", "Create the first master idea, then adapt it for each platform.")]));
}

function renderCalendar() {
  const scheduled = state.content.filter((item) => item.scheduledAt).sort((a, b) => a.scheduledAt.localeCompare(b.scheduledAt));
  const days = new Map();
  scheduled.forEach((item) => {
    const day = item.scheduledAt.slice(0, 10);
    if (!days.has(day)) days.set(day, []);
    days.get(day).push(item);
  });
  const cards = [...days.entries()].map(([day, items]) => {
    const ideas = new Set(items.map((item) => item.campaignId || item.id));
    const card = create("article", `calendar-day${ideas.size >= (state.calendarSettings?.maximumIdeasPerDay || 3) ? " full" : ""}`);
    const header = create("div", "calendar-head");
    header.append(create("h3", "", new Date(`${day}T12:00:00`).toLocaleDateString("en-GB", { weekday: "long", day: "numeric", month: "long" })), chip(`${ideas.size}/3 ideas`, ideas.size === 3));
    card.append(header);
    items.forEach((item) => {
      const account = state.accounts.find((value) => value.id === item.accountId);
      const row = create("div", "calendar-row");
      row.append(create("time", "", item.scheduledAt.slice(11, 16)), create("div", "", item.title), create("span", "", accountLabel(account)), chip(statusLabel(item.status)));
      card.append(row);
    });
    return card;
  });
  $("#calendar-board").replaceChildren(...(cards.length ? cards : [create("div", "empty", "No variants scheduled. Add a date and time in a content variant.")]));
}

function statusLabel(value) {
  return String(value || "DRAFT").replaceAll("_", " ");
}

function actionButton(label, action, item, style = "secondary") {
  const button = create("button", `button small ${style}`, label);
  button.type = "button";
  button.addEventListener("click", async () => {
    let extra = {};
    if (action === "compliance_review") extra.note = window.prompt("Record the compliance review note:", "Checked for privacy, safety and claim risk.") || "";
    if (action === "founder_reject") extra.note = window.prompt("Reason for returning this item:", "") || "";
    if (action === "mark_published") extra.url = window.prompt("Paste the public post URL after manual publishing:", "") || "";
    try {
      await api("/api/content/action", { id: item.id, action, ...extra });
      renderAll();
      toast(`${item.id}: ${label} recorded.`);
    } catch (error) { toast(error.message, true); }
  });
  return button;
}

function actionSet(item) {
  const wrap = create("div", "content-actions");
  if (!["MANUALLY_PUBLISHED", "MEASURED"].includes(item.status)) {
    const edit = create("button", "button small secondary", "Edit draft");
    edit.type = "button";
    edit.addEventListener("click", () => openEditor(item));
    wrap.append(edit);
  }
  const map = {
    DRAFT: [["Run brand check", "brand_check", "secondary"]],
    CORRECTION_REQUIRED: [["Run brand check again", "brand_check", "secondary"]],
    BRAND_REVIEWED: item.risk === "routine" ? [["Send to Founder", "submit_founder", "gold"]] : [["Record compliance review", "compliance_review", "secondary"]],
    COMPLIANCE_REVIEWED: item.risk === "spend" && !item.budgetApproval ? [["Approve budget", "budget_approve", "secondary"]] : [["Send to Founder", "submit_founder", "gold"]],
    FOUNDER_REVIEW: [["Approve exact preview", "founder_approve", "gold"], ["Return with note", "founder_reject", "danger"]],
    APPROVED: [["Export publishing pack", "export", "secondary"], ["Mark manually published", "mark_published", "gold"]],
    REJECTED: [["Return to draft", "return_draft", "secondary"]],
    MANUALLY_PUBLISHED: [["Mark measured", "mark_measured", "secondary"]],
  };
  for (const [label, action, style] of map[item.status] || []) {
    if (action === "export") {
      const link = create("a", `button small ${style}`, label);
      link.href = `${API_ROOT}/api/export/${encodeURIComponent(item.id)}`;
      link.target = "_blank";
      link.rel = "noopener";
      wrap.append(link);
    } else wrap.append(actionButton(label, action, item, style));
  }
  return wrap;
}

function contentCard(item, approvalMode = false) {
  const card = create("article", "content-card");
  const top = create("div", "content-top");
  const heading = create("div");
  heading.append(create("p", "eyebrow", `${item.id} · ${item.pillar}`), create("h3", "", item.title));
  top.append(heading, chip(statusLabel(item.status), ["FOUNDER_REVIEW", "APPROVED"].includes(item.status)));
  card.append(top);
  const meta = create("div", "content-meta");
  const campaign = state.campaigns.find((value) => value.id === item.campaignId);
  const account = state.accounts.find((value) => value.id === item.accountId);
  meta.append(chip(item.platform), chip(item.format), chip(item.risk), chip(campaign ? campaign.title : "No master idea"), chip(accountLabel(account)));
  if (item.scheduledAt) meta.append(chip(`${item.scheduledAt.replace("T", " ")} · ${item.scheduleTimezone || state.calendarSettings?.timezone || "local"}`, true));
  card.append(meta, create("p", "content-summary", approvalMode ? item.body : item.objective));
  if (approvalMode) {
    const preview = create("div", "review-box");
    preview.append(
      create("strong", "", "Exact public preview"),
      create("p", "", `Account: ${accountLabel(account)}`),
      create("p", "", `Schedule: ${item.scheduledAt || "Manual / not scheduled"} ${item.scheduleTimezone || ""}`),
      create("p", "", `Hook: ${item.hook}`),
      create("p", "", `Caption: ${item.caption}`),
      create("p", "", `CTA: ${item.cta}`),
      create("p", "", `Destination: ${item.destination}`),
      create("p", "", `Media: ${item.assetRef || "No media reference"}`),
      create("p", "", `Media fingerprint: ${item.assetSha256 || "Not recorded"}`),
    );
    if (item.reviewHash) preview.append(create("p", "hash", `Preview fingerprint: ${item.reviewHash}`));
    card.append(preview);
  }
  if (item.brandCheck) {
    const review = create("div", `review-box ${item.brandCheck.passed ? "good" : "bad"}`);
    review.append(create("strong", "", item.brandCheck.passed ? "Brand check passed" : "Corrections required"));
    if (item.brandCheck.issues?.length) {
      const list = create("ul");
      item.brandCheck.issues.forEach((issue) => list.append(create("li", "", issue.message)));
      review.append(list);
    }
    card.append(review);
  }
  card.append(actionSet(item));
  return card;
}

function renderPipeline() {
  const statuses = ["ALL", ...new Set(state.content.map((item) => item.status))];
  $("#pipeline-filters").replaceChildren(...statuses.map((status) => {
    const button = create("button", `filter${activeFilter === status ? " active" : ""}`, statusLabel(status));
    button.type = "button";
    button.addEventListener("click", () => { activeFilter = status; renderPipeline(); });
    return button;
  }));
  const items = activeFilter === "ALL" ? state.content : state.content.filter((item) => item.status === activeFilter);
  const target = $("#content-list");
  target.replaceChildren(...(items.length ? items.map((item) => contentCard(item)) : [create("div", "empty", "No content in this stage.")]));
}

function renderApproval() {
  const items = state.content.filter((item) => ["FOUNDER_REVIEW", "APPROVED"].includes(item.status));
  $("#approval-list").replaceChildren(...(items.length ? items.map((item) => contentCard(item, true)) : [create("div", "empty", "Nothing is waiting for Founder approval.")]));
}

function renderResearch() {
  const cards = [...state.research].reverse().map((item) => {
    const card = create("article", "memory-card");
    card.append(create("p", "eyebrow", `${item.id} · ${item.audience}`), create("h3", "", item.headline), create("p", "", item.observation), create("p", "", `Opportunity: ${item.opportunity}`));
    const link = create("a", "hash", item.sourceUrl);
    link.href = item.sourceUrl; link.target = "_blank"; link.rel = "noopener";
    card.append(link);
    return card;
  });
  $("#research-list").replaceChildren(...(cards.length ? cards : [create("div", "empty", "No research signals saved yet.")]));
}

function renderInspiration() {
  const cards = [...(state.inspiration || [])].reverse().map((item) => {
    const card = create("article", "memory-card inspiration-card");
    card.append(
      create("p", "eyebrow", `${item.id} · ${item.platform || "Source"}`),
      create("h3", "", item.status === "DUPLICATE" ? "Repeat captured" : "Saved for later review"),
    );
    const link = create("a", "source-link", item.sourceUrl);
    link.href = item.sourceUrl;
    link.target = "_blank";
    link.rel = "noopener";
    card.append(link);
    if (item.note) card.append(create("p", "", item.note));
    if (item.duplicateOf) card.append(create("p", "review-box", `Exact URL already saved as ${item.duplicateOf}. Both entries remain in the intake record.`));
    card.append(chip(item.status || "CAPTURED", item.status !== "DUPLICATE"));
    return card;
  });
  $("#inspiration-list").replaceChildren(...(cards.length ? cards : [create("div", "empty", "No videos captured yet. During collection, every link is remembered without being executed.")]));
}

function renderCommunity() {
  const cards = [...state.community].reverse().map((item) => {
    const card = create("article", "memory-card");
    card.append(create("p", "eyebrow", `${item.id} · ${item.platform}`), create("h3", "", statusLabel(item.status)), create("p", "", item.message));
    if (item.humanOnly) card.append(create("p", "review-box bad", "Human-only: do not publish an automated reply."));
    else if (item.draftReply) card.append(create("p", "review-box good", `Draft only: ${item.draftReply}`));
    return card;
  });
  $("#community-list").replaceChildren(...(cards.length ? cards : [create("div", "empty", "No inbound items recorded.")]));
}

function renderMetrics() {
  const eligible = state.content.filter((item) => ["MANUALLY_PUBLISHED", "MEASURED"].includes(item.status));
  const select = $("#metric-content");
  select.replaceChildren(...eligible.map((item) => {
    const option = create("option", "", `${item.id} — ${item.title}`); option.value = item.id; return option;
  }));
  const submit = $("#metrics-form button[type=submit]");
  submit.disabled = !eligible.length;
  const cards = [...state.metrics].reverse().map((item) => {
    const card = create("article", "memory-card");
    card.append(create("p", "eyebrow", `${item.id} · ${item.contentId}`), create("h3", "", `${item.views || 0} views · ${item.engagements || 0} engagements`), create("p", "", item.outcome), create("p", "", `Next lesson: ${item.lesson}`));
    return card;
  });
  $("#metrics-list").replaceChildren(...(cards.length ? cards : [create("div", "empty", "Metrics begin after an approved item is manually published.")]));
}

function renderAll() {
  renderStats(); renderAgents(); renderAccounts(); renderCampaigns(); renderCalendar(); renderPipeline(); renderApproval(); renderResearch(); renderInspiration(); renderCommunity(); renderMetrics();
}

function openEditor(item = null) {
  const form = $("#content-form");
  form.reset();
  $("#content-form-title").textContent = item ? `Edit ${item.id}` : "New content";
  if (item) {
    for (const name of ["id", "title", "campaignId", "accountId", "pillar", "platform", "format", "objective", "hook", "body", "caption", "cta", "destination", "risk", "budgetGbp", "scheduledAt", "scheduleTimezone", "assetRef", "assetSha256"]) {
      if (form.elements[name]) form.elements[name].value = item[name] ?? "";
    }
    form.elements.sources.value = (item.sources || []).join?.("\n") || "";
  }
  $("#content-dialog").showModal();
}

async function submitSimple(form, path) {
  const values = Object.fromEntries(new FormData(form));
  try { await api(path, values); form.reset(); renderAll(); toast("Saved to the local command centre."); }
  catch (error) { toast(error.message, true); }
}

async function boot() {
  state = await api("/api/state");
  for (const selector of ["#pillar-select", "#campaign-pillar"]) {
    const pillar = $(selector);
    pillar.replaceChildren(...state.pillars.map((value) => { const option = create("option", "", value); option.value = value; return option; }));
  }
  $("#content-campaign").replaceChildren(...state.campaigns.map((campaign) => {
    const option = create("option", "", `${campaign.id} — ${campaign.title}`); option.value = campaign.id; return option;
  }));
  $("#content-account").replaceChildren(...state.accounts.map((account) => {
    const option = create("option", "", accountLabel(account)); option.value = account.id; return option;
  }));
  $("#content-form").elements.scheduleTimezone.value = state.calendarSettings?.timezone || "Europe/London";
  renderAll();
}

$$(".nav-item").forEach((button) => button.addEventListener("click", () => showView(button.dataset.view)));
$$('[data-go]').forEach((button) => button.addEventListener("click", () => showView(button.dataset.go)));
$("#new-content-button").addEventListener("click", () => openEditor());
$("#close-dialog").addEventListener("click", () => $("#content-dialog").close());
$("#cancel-dialog").addEventListener("click", () => $("#content-dialog").close());
$("#close-account-dialog").addEventListener("click", () => $("#account-dialog").close());
$("#cancel-account-dialog").addEventListener("click", () => $("#account-dialog").close());
$("#content-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  const form = event.currentTarget;
  const values = Object.fromEntries(new FormData(form));
  values.sources = values.sources.split("\n").map((value) => value.trim()).filter(Boolean);
  const path = values.id ? "/api/content/update" : "/api/content/new";
  try { await api(path, values); $("#content-dialog").close(); renderAll(); toast(values.id ? "Draft updated. Earlier approvals were cleared." : "New draft created."); }
  catch (error) { toast(error.message, true); }
});
$("#research-form").addEventListener("submit", (event) => { event.preventDefault(); submitSimple(event.currentTarget, "/api/research/new"); });
$("#campaign-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  const form = event.currentTarget;
  const values = Object.fromEntries(new FormData(form));
  const path = values.id ? "/api/campaign/update" : "/api/campaign/new";
  try {
    await api(path, values);
    form.reset();
    await boot();
    toast(values.id ? "Master idea updated." : "Master idea created. Add its platform variants next.");
  } catch (error) { toast(error.message, true); }
});
$("#account-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  const values = Object.fromEntries(new FormData(event.currentTarget));
  try {
    await api("/api/account/update", values);
    $("#account-dialog").close();
    await boot();
    toast(`${values.platform}: non-secret account record updated.`);
  } catch (error) { toast(error.message, true); }
});
$("#inspiration-form").addEventListener("submit", (event) => { event.preventDefault(); submitSimple(event.currentTarget, "/api/inspiration/new"); });
$("#community-form").addEventListener("submit", (event) => { event.preventDefault(); submitSimple(event.currentTarget, "/api/community/new"); });
$("#metrics-form").addEventListener("submit", (event) => { event.preventDefault(); submitSimple(event.currentTarget, "/api/metrics/new"); });

boot().catch((error) => toast(error.message, true));

if (!window.location.pathname.startsWith("/marketing")) $("#aios-back").hidden = true;
