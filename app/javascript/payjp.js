let _payjp = null;

document.addEventListener('turbo:load',  mountPayjp);
document.addEventListener('turbo:render', mountPayjp);
document.addEventListener('turbo:before-cache', cleanupPayjp);

function cleanupPayjp() {
  const form = document.getElementById('charge-form');
  if (!form) return;

  if (form._payjpOnSubmit) {
    form.removeEventListener('submit', form._payjpOnSubmit);
    form._payjpOnSubmit = null;
  }
  ['number-form','expiry-form','cvc-form'].forEach((id) => {
    const host = document.getElementById(id);
    if (host) host.innerHTML = '';
  });
  const tokenInput = document.getElementById('token');
  if (tokenInput) tokenInput.value = '';

  // リトライカウンタもリセット
  form.dataset.payjpTries = '';
  form.dataset.payjpReady = '0';
}

async function mountPayjp() {
  const form = document.getElementById('charge-form');
  if (!form) return;

  form.dataset.payjpReady = '0';
  form.dataset.payjpTries = '';
  const btn0 = form.querySelector('input[type="submit"],button[type="submit"]');
  if (btn0) btn0.disabled = false;

  // 既に初期化済みなら何もしない
  if (form.dataset.payjpReady === '1' && form._payjpOnSubmit) return;

  // リトライ上限（例: 40回 = 約2秒 50ms間隔）
  const tries = parseInt(form.dataset.payjpTries || '0', 10);
  if (tries > 120) return;

  const pk = document.querySelector('meta[name="payjp-public-key"]')?.content;

  // SDK or 公開鍵が未準備なら少し待って再挑戦
  if (!pk || !window.Payjp) {
    form.dataset.payjpTries = String(tries + 1);
    setTimeout(mountPayjp, 50);
    return;
  }

  // ここから初期化
  if (form._payjpOnSubmit) {
    form.removeEventListener('submit', form._payjpOnSubmit);
    form._payjpOnSubmit = null;
  }
  ['number-form','expiry-form','cvc-form'].forEach((id) => {
    const host = document.getElementById(id);
    if (host) host.innerHTML = '';
  });

  if (!_payjp) _payjp = Payjp(pk);
  const elements = _payjp.elements();

  const numberEl = elements.create('cardNumber');
  const expiryEl = elements.create('cardExpiry');
  const cvcEl    = elements.create('cardCvc');

  numberEl.mount('#number-form');
  expiryEl.mount('#expiry-form');
  cvcEl.mount('#cvc-form');

  const onSubmit = async (e) => {
    e.preventDefault();
    const btn = form.querySelector('input[type="submit"],button[type="submit"]');
    if (btn) btn.disabled = true;

    try {
      const { id, error } = await _payjp.createToken(numberEl);

      if (error) {
        // 失敗時もサーバに投げて部分テンプレのエラーを表示させる
        if (btn) btn.disabled = false;

        let tokenInput = document.getElementById('token');
        if (!tokenInput) {
          tokenInput = document.createElement('input');
          tokenInput.type = 'hidden';
          tokenInput.name = 'order_address[token]';
          tokenInput.id   = 'token';
          form.appendChild(tokenInput);
        }
        tokenInput.value = '';

        form.removeEventListener('submit', onSubmit);
        form.submit(); // 422で戻る→エラーメッセージ表示
        return;
      }

      // 成功時はトークンを詰める
      let tokenInput = document.getElementById('token');
      if (!tokenInput) {
        tokenInput = document.createElement('input');
        tokenInput.type = 'hidden';
        tokenInput.name = 'order_address[token]';
        tokenInput.id   = 'token';
        form.appendChild(tokenInput);
      }
      tokenInput.value = id;

      form.removeEventListener('submit', onSubmit);
      form.submit();
    } finally {
      // 送信しなかったケースだけボタン解除（念のため）
      // 成功/失敗いずれも submit しているので通常は不要
    }
  };

  form.addEventListener('submit', onSubmit);
  form._payjpOnSubmit = onSubmit;
  form.dataset.payjpReady = '1';
  form.dataset.payjpTries = '';
}
