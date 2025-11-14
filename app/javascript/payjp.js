let _payjp = null;

document.addEventListener('turbo:load',  mountPayjp);
document.addEventListener('turbo:render', mountPayjp);
document.addEventListener('turbo:before-cache', cleanupPayjp);

// Turboがページをキャッシュする直前に必ずクリーンアップ
function cleanupPayjp() {
  const form = document.getElementById('charge-form');
  if (!form) return;

  if (form._payjpOnSubmit) {
    form.removeEventListener('submit', form._payjpOnSubmit);
    form._payjpOnSubmit = null;
  }
  ['number-form','expiry-form','cvc-form'].forEach((id) => {
    const host = document.getElementById(id);
    if (host) host.innerHTML = ''; // iframe撤去
  });

  const tokenInput = document.getElementById('token');
  if (tokenInput) tokenInput.value = '';

  form.dataset.payjpReady = '0';
  form.dataset.payjpTries = '';
}

async function mountPayjp() {
  const form = document.getElementById('charge-form');
  if (!form) return;

  // 既存ハンドラが残っていたら外す（重複送信防止）
  if (form._payjpOnSubmit) {
    form.removeEventListener('submit', form._payjpOnSubmit);
    form._payjpOnSubmit = null;
  }

  // SDKと公開鍵の準備を待つ（ログイン直後の復元対策）
  const tries = parseInt(form.dataset.payjpTries || '0', 10);
  const pk = document.querySelector('meta[name="payjp-public-key"]')?.content;
  if (!pk || !window.Payjp) {
    if (tries > 120) return; // 約6秒で諦め
    form.dataset.payjpTries = String(tries + 1);
    setTimeout(mountPayjp, 50);
    return;
  }

  // ホストを毎回空にしてから新規Elementsをマウント（“既にインスタンス化”回避）
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

  // 送信時：このクロージャが “この回の numberEl” を握るのが重要
  const onSubmit = async (e) => {
    e.preventDefault();
    const btn = form.querySelector('input[type="submit"],button[type="submit"]');
    if (btn) btn.disabled = true;

    try {
      const { id, error } = await _payjp.createToken(numberEl);

      let tokenInput = document.getElementById('token');
      if (!tokenInput) {
        tokenInput = document.createElement('input');
        tokenInput.type = 'hidden';
        tokenInput.name = 'order_address[token]';
        tokenInput.id   = 'token';
        form.appendChild(tokenInput);
      }

      if (error) {
        // 失敗時は空トークンでサーバに投げ、フォームのエラー部分テンプレを表示
        tokenInput.value = '';
        if (btn) btn.disabled = false;
        form.removeEventListener('submit', onSubmit);
        form.submit(); // 422 → エラー表示
        return;
      }

      // 成功
      tokenInput.value = id;
      form.removeEventListener('submit', onSubmit);
      form.submit();
    } finally {
      // 送信しているので通常は不要（ここで btn を戻さない）
    }
  };

  form.addEventListener('submit', onSubmit);
  form._payjpOnSubmit = onSubmit;
  form.dataset.payjpReady = '1';
  form.dataset.payjpTries = '';
}
