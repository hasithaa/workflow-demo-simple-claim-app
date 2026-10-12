// Helpers shared by the claims and admin contexts: the signed-in user, rendering, toasts and dialogs.

export const esc = (s) => String(s ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
export const money = (n) => Number(n).toLocaleString('en-US', { style: 'currency', currency: 'USD' });
export const initials = (name) => name.split(' ').map((w) => w[0]).join('');

// Display names for the people the apps mention; anyone else shows by email.
const NAMES = { 'ann@example.com': 'Ann Lee', 'jane@example.com': 'Jane Moreno' };
export const nameOf = (email) => NAMES[email] || email;

export function when(iso) {
  const d = new Date(iso);
  const mins = Math.round((Date.now() - d.getTime()) / 60000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins} min ago`;
  if (mins < 60 * 24) return `${Math.round(mins / 60)} h ago`;
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

// The signed-in user from the identity service, or a trip to the sign-in page.
export async function signedInUser() {
  const res = await fetch('/auth/me', { cache: 'no-store' });
  if (res.ok) {
    const user = await res.json();
    user.roleList = user.roles.split(',').map((r) => r.trim());
    return user;
  }
  location.href = `/login/?next=${encodeURIComponent(location.pathname)}`;
  return new Promise(() => {});
}

export function topbar(app, user) {
  return `<header class="topbar">
      <div class="brand"><span class="logo">${app.icon}</span><span>${esc(app.name)}<small>Northbridge</small></span></div>
      <nav class="contexts">
        <a href="/claims/" class="${app.context === 'claims' ? 'on' : ''}">My claims</a>
        ${user.roleList.includes('MANAGER') ? `<a href="/admin/" class="${app.context === 'admin' ? 'on' : ''}">Approvals</a>` : ''}
      </nav>
      <div class="spacer"></div>
      <div class="who" id="who"><span class="avatar">${initials(user.name)}</span>
        <span><div class="name">${esc(user.name)}</div><div class="role">${esc(user.title)}</div></span></div>
      <button class="link" id="signout">Sign out</button></header><div id="toasts"></div>`;
}

export function wireSignOut() {
  document.getElementById('signout').addEventListener('click', async () => {
    await fetch('/auth/logout', { method: 'POST' });
    location.href = `/login/?next=${encodeURIComponent(location.pathname)}`;
  });
}

export function toast(message, kind = '') {
  let box = document.getElementById('toasts');
  if (!box) {
    box = document.createElement('div');
    box.id = 'toasts';
    document.body.appendChild(box);
  }
  const t = document.createElement('div');
  t.className = `toast ${kind}`;
  t.textContent = message;
  box.appendChild(t);
  setTimeout(() => t.remove(), 4000);
}

export function dialog(html, className = '') {
  const back = document.createElement('div');
  back.className = `backdrop ${className}`;
  back.innerHTML = `<div class="dialog">${html}</div>`;
  back.addEventListener('click', (e) => { if (e.target === back) back.remove(); });
  document.body.appendChild(back);
  return back;
}

export function showBill(url, name) {
  const box = dialog(`<h3>${esc(name)}</h3><div class="meta">Bill attached to the claim</div>
    <img src="${esc(url)}" alt="${esc(name)}"><div class="actions"><button class="btn" data-close>Close</button></div>`, 'lightbox');
  box.querySelector('[data-close]').addEventListener('click', () => box.remove());
}

export const STATUS = {
  SUBMITTING: 'Submitting',
  BILL_REQUIRED: 'Bill required',
  IN_REVIEW: 'Waiting for approval',
  APPROVED: 'Approved',
  REJECTED: 'Rejected',
};
