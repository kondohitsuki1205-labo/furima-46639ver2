// app/javascript/payjp.js
let payjpCtx = null; // { form, numberEl, expiryEl, cvcEl, onSubmit }

function teardownPayjp() {
  if (!payjpCtx) return;
  const { numberEl, expiryEl, cvcEl, form, onSubmit } = payjpCtx;
  try { numberEl?.unmount?.(); } catch (_) {}
  try { expiryEl?.unmount?.(); } catch (_) {}
  try { cvcEl?.unmount?.(); } catch (_) {}
  if (form && onSubmit) form.removeEventListener('submit', onSubmit);
  payjpCtx = null;

  // カード欄だけ初期化（Turboキャッシュ対策）
  ['number-form', 'expiry-form', 'cvc-form'].forEach((id) => {
    const host = document.getElementById(id);
    if (host) host.innerHTML = '';
  });
  const tokenInput = document.getElementById('token');
  if (tokenInput) tokenInput.value = '';
  const ce = document.getElementById('card-errors');
  if (ce) ce.textContent = '';
}

function mountPayjp() {
  const form = document.getElementById('charge-form');
  if (!form) return;

  // 既存を必ず破棄してから作り直す（「既にインスタンス化されています」対策）
  teardownPayjp();

  const numberHost = document.getElementById('number-form');
  const expiryHost = document.getElementById('expiry-form');
  const cvcHost    = document.getElementById('cvc-form');
  if (!numberHost || !expiryHost || !cvcHost) return;

  const pk = document.querySelector('meta[name="payjp-public-key"]')?.content;
  if (!pk || !window.Payjp) return;

  const payjp    = Payjp(pk);
  const elements = payjp.elements();

  const numberEl = elements.create('cardNumber');
  const expiryEl = elements.create('cardExpiry');
  const cvcEl    = elements.create('cardCvc');

  numberEl.mount('#number-form');
  expiryEl.mount('#expiry-form');
  cvcEl.mount('#cvc-form');

  const ce = document.getElementById('card-errors');

  const onSubmit = async (e) => {
    e.preventDefault();

    const btn = form.querySelector('input[type="submit"],button[type="submit"]');
    if (btn) btn.disabled = true;
    if (ce) ce.textContent = '';

    try {
      // ① クライアント側：カードトークン化
      const { id, error } = await payjp.createToken(numberEl);

      if (error) {
        // 失敗→サーバ送信しない。カード欄だけ初期化して再マウント＆エラー表示
        if (btn) btn.disabled = false;
        if (ce) ce.textContent = error.message || 'カード情報を確認してください。';
        teardownPayjp();
        mountPayjp();
        return;
      }

      // 成功→hiddenに詰めて送信（以降は②サーバ側の住所等バリデーション）
      let tokenInput = document.getElementById('token');
      if (!tokenInput) {
        tokenInput = document.createElement('input');
        tokenInput.type = 'hidden';
        tokenInput.name = 'order_address[token]';
        tokenInput.id   = 'token';
        form.appendChild(tokenInput);
      }
      tokenInput.value = id;

      form.submit();
    } catch {
      if (btn) btn.disabled = false;
      if (ce) ce.textContent = '通信エラーが発生しました。時間をおいて再度お試しください。';
      teardownPayjp();
      mountPayjp();
    }
  };

  form.addEventListener('submit', onSubmit);
  payjpCtx = { form, numberEl, expiryEl, cvcEl, onSubmit };
}

// Turboライフサイクル：ページ遷移/再描画ごとに安全に再初期化
document.addEventListener('turbo:load',   mountPayjp);
document.addEventListener('turbo:render', mountPayjp);
document.addEventListener('turbo:before-cache', teardownPayjp);

// サーバ側422（住所などの検証エラー）で戻った時はカード欄だけ空にして再マウント
document.addEventListener('turbo:submit-end', (e) => {
  const form = document.getElementById('charge-form');
  if (!form) return;
  if (e.target !== form) return;
  if (e.detail?.success === false) {
    teardownPayjp();
    mountPayjp();
  }
});
