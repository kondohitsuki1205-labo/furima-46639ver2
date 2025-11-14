let _payjp = null;

document.addEventListener('turbo:load',  mountPayjp);
document.addEventListener('turbo:render', mountPayjp);

// ← これが重要：ページがキャッシュ保存される直前に“きれいに片付ける”
document.addEventListener('turbo:before-cache', () => {
  const form = document.getElementById('charge-form');
  if (!form) return;

  if (form._payjpOnSubmit) {
    form.removeEventListener('submit', form._payjpOnSubmit);
    form._payjpOnSubmit = null;
  }

  ['number-form', 'expiry-form', 'cvc-form'].forEach((id) => {
    const host = document.getElementById(id);
    if (host) host.innerHTML = '';
  });

  const tokenInput = document.getElementById('token');
  if (tokenInput) tokenInput.value = '';
});

function mountPayjp() {
  const form = document.getElementById('charge-form');
  if (!form) return;

  // 二重バインド防止
  if (form._payjpOnSubmit) {
    form.removeEventListener('submit', form._payjpOnSubmit);
    form._payjpOnSubmit = null;
  }

  // マウント先を毎回空に
  ['number-form', 'expiry-form', 'cvc-form'].forEach((id) => {
    const host = document.getElementById(id);
    if (host) host.innerHTML = '';
  });

  // 公開鍵/SDK確認
  const pk = document.querySelector('meta[name="payjp-public-key"]')?.content;
  if (!pk || !window.Payjp) return;

  // Payjp本体は使い回しでOK
  if (!_payjp) _payjp = Payjp(pk);

  // ★ elementsは毎回作り直す（ここが肝）
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
        if (btn) btn.disabled = false;

        // 空トークンを必ず送ってRails側で "Token can't be blank" を表示させる
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
        form.submit(); // 422で戻り、エラーパーツが出る
        return;
      }

      // 成功：トークン格納して通常送信
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
      // 必要ならローディング解除等
    }
  };

  form.addEventListener('submit', onSubmit);
  form._payjpOnSubmit = onSubmit;
}
