// Signs in with the identity service; the session is an HttpOnly cookie, so the apps never handle the token.

import { toast } from '/shared/ui.js';

const next = new URLSearchParams(location.search).get('next') || '/claims/';

document.getElementById('signin').addEventListener('submit', async (e) => {
  e.preventDefault();
  const username = document.getElementById('email').value.trim().toLowerCase();
  const password = document.getElementById('password').value;
  const res = await fetch('/auth/login', { method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password }) });
  if (!res.ok) {
    toast('Wrong email or password', 'bad');
    return;
  }
  // Only same-site paths, so a crafted link cannot send a signed-in user elsewhere.
  location.href = next.startsWith('/') && !next.startsWith('//') ? next : '/claims/';
});
