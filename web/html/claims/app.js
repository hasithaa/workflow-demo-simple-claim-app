// Claims context: the employee side. Lists the signed-in employee's claims, files new ones and uploads bills.
// Every status comes from the claims integration; the app holds no process logic.

import { signedInUser, topbar, wireSignOut, toast, dialog, showBill, esc, money, when, claimNo, STATUS } from '/shared/ui.js';
import { api } from '/shared/auth.js';

const APP = { name: 'Expenses', icon: '$', context: 'claims' };
let user = null;
// Claims just submitted, shown until the workflow has recorded them.
const submitting = new Map();
let known = null;

async function start() {
  user = await signedInUser();
  document.body.innerHTML = `${topbar(APP, user)}<main>
      <div class="page-head"><div><h1>My claims</h1><p>Expense claims you have filed</p></div>
        <div class="spacer"></div><button class="btn primary" id="new-claim">+ New claim</button></div>
      <div id="claims"></div></main>`;
  wireSignOut();
  document.getElementById('new-claim').addEventListener('click', newClaim);
  refresh();
}

async function refresh() {
  if (!user) return;
  try {
    const res = await api(`/api/claims?employee=${encodeURIComponent(user.username)}`);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    render(await res.json());
  } catch (e) {
    console.warn('claims refresh failed', e);
  }
}

function render(claims) {
  const box = document.getElementById('claims');
  if (!box || document.querySelector('.backdrop')) return;
  for (const c of claims) submitting.delete(c.claimId);
  const all = [...submitting.values(), ...claims];
  const signature = JSON.stringify(all.map((c) => [c.claimId, c.status, c.comment]));
  if (signature === box.dataset.signature) return;
  box.dataset.signature = signature;
  const before = known;
  known = new Map(all.map((c) => [c.claimId, c.status]));
  box.innerHTML = all.length ? all.map((c) => card(c, before && before.get(c.claimId) !== c.status)).join('')
    : '<div class="empty"><div class="big">🧾</div>No claims yet</div>';
  box.querySelectorAll('[data-bill]').forEach((b) => b.addEventListener('click', () => uploadBill(b.dataset.bill)));
  box.querySelectorAll('[data-view]').forEach((b) => b.addEventListener('click', () => showBill(b.dataset.view, b.dataset.name)));
}

const STEPS = ['Submitted', 'Bill', 'Manager approval', 'Done'];

function progress(status) {
  const reached = { SUBMITTING: 0, BILL_REQUIRED: 1, IN_REVIEW: 2, APPROVED: 4, REJECTED: 4 }[status];
  return `<div class="steps">${STEPS.map((label, i) => {
    let cls = i < reached ? 'done' : i === reached ? 'now' : '';
    if (status === 'REJECTED' && i === 2) cls = 'failed';
    const mark = cls === 'done' ? '✓' : cls === 'failed' ? '✕' : '';
    const text = status === 'REJECTED' && i === 2 ? 'Rejected' : label;
    return `<div class="s ${cls}"><span class="dot">${mark}</span>${text}</div>`
      + (i < STEPS.length - 1 ? `<div class="bar ${i < reached ? 'done' : ''}"></div>` : '');
  }).join('')}</div>`;
}

function card(c, changed) {
  const action = c.status === 'BILL_REQUIRED'
    ? `<button class="btn primary" data-bill="${esc(c.claimId)}">Submit bill</button>`
    : c.billUrl ? `<button class="btn" data-view="${esc(c.billUrl)}" data-name="${esc(c.billName)}">View bill</button>` : '';
  const note = c.comment ? `<div class="note"><b>Manager:</b> ${esc(c.comment)}</div>` : '';
  return `<div class="card${changed ? ' fresh' : ''}" data-claim="${esc(c.claimId)}">
      <div class="row">
        <div style="flex:1;min-width:0"><div class="title">${esc(c.description)}</div>
          <div class="meta">${esc(claimNo(c.claimId))} · submitted ${when(c.submittedAt)}</div></div>
        <div class="amount">${money(c.amount)}</div>
        <span class="pill ${c.status}" data-status="${c.status}">${STATUS[c.status]}</span>
        ${action}
      </div>${progress(c.status)}${note}</div>`;
}

function newClaim() {
  const box = dialog(`<h3>New expense claim</h3><div class="meta">Submit now; you will be asked for the bill next.</div>
      <form id="claim-form">
        <label for="description">What is it for?</label><input id="description" type="text">
        <label for="amount">Amount (USD)</label><input id="amount" type="number" step="0.01" min="0">
        <div class="actions"><button class="btn" type="button" data-close>Cancel</button>
          <button class="btn primary" type="submit">Submit claim</button></div></form>`);
  box.querySelector('[data-close]').addEventListener('click', () => box.remove());
  box.querySelector('#claim-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const description = box.querySelector('#description').value.trim();
    const amount = Number(box.querySelector('#amount').value);
    if (!description || !(amount > 0)) return;
    e.submitter.disabled = true;
    const claim = { employee: user.username, description, amount };
    const res = await api('/api/claims', { method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(claim) });
    if (!res.ok) {
      toast('The claim could not be submitted', 'bad');
      e.submitter.disabled = false;
      return;
    }
    // The claims system answers with the new claim's id, which is its workflow's id.
    const claimId = (await res.text()).trim().replace(/^"|"$/g, '');
    submitting.set(claimId, { ...claim, claimId, status: 'SUBMITTING', submittedAt: new Date().toISOString() });
    box.remove();
    toast(`${claimNo(claimId)} submitted`, 'good');
    refresh();
  });
}

// The bill goes to the claim's own workflow: the claim id is the workflow id.
function uploadBill(claimId) {
  const box = dialog(`<h3>Submit bill</h3><div class="meta">${esc(claimNo(claimId))} is waiting for its bill.</div>
      <div class="drop" id="drop"><div>Drop the bill here, or</div>
        <button class="btn" type="button" id="choose" style="margin-top:8px">Choose file</button>
        <input type="file" id="file" accept="image/*,application/pdf" hidden></div>
      <div class="actions"><button class="btn" type="button" data-close>Cancel</button>
        <button class="btn primary" id="upload" disabled>Upload</button></div>`);
  const input = box.querySelector('#file');
  box.querySelector('[data-close]').addEventListener('click', () => box.remove());
  box.querySelector('#choose').addEventListener('click', () => input.click());
  input.addEventListener('change', () => {
    const file = input.files[0];
    if (!file) return;
    const drop = box.querySelector('#drop');
    drop.classList.add('has-file');
    drop.innerHTML = `<div class="file">📄 ${esc(file.name)}</div><div class="meta">${Math.round(file.size / 1024)} KB</div>`;
    box.querySelector('#upload').disabled = false;
  });
  box.querySelector('#upload').addEventListener('click', async (e) => {
    const file = input.files[0];
    e.target.disabled = true;
    const fileUrl = `/files/${encodeURIComponent(claimId)}/${encodeURIComponent(file.name)}`;
    const stored = await api(fileUrl, { method: 'PUT', body: file });
    const sent = stored.ok && await api(`/api/claims/${encodeURIComponent(claimId)}/bill`, { method: 'POST',
      headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ fileName: file.name, fileUrl }) });
    if (!sent || !sent.ok) {
      toast('The bill could not be uploaded', 'bad');
      e.target.disabled = false;
      return;
    }
    box.remove();
    toast(`Bill attached to ${claimNo(claimId)}`, 'good');
    refresh();
  });
}

start();
setInterval(refresh, 2000);
