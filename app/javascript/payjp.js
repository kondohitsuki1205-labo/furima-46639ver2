let _payjp = null;
let _elements = null;

document.addEventListener('turbo:load',  mountPayjp);
document.addEventListener('turbo:render', mountPayjp);

function mountPayjp() {
  const form = document.getElementById('charge-form');
  if (!form) return;

  // 既存ハンドラを外す（重複送信防止）
  if (form._payjpOnSubmit) {
    form.removeEventListener('submit', form._payjpOnSubmit);
    form._payjpOnSubmit = null;
  }

  // 既存のElementsをアンマウント（turbo再描画対応）
  ['number-form', 'expiry-form', 'cvc-form'].forEach((id) => {
    const host = document.getElementById(id);
    if (host) host.innerHTML = '';
  });

  // 公開鍵とSDKの存在確認
  const pk = document.querySelector('meta[name="payjp-public-key"]')?.content;
  if (!pk || !window.Payjp) return;

  // Payjp/Elementsは1度だけ生成して使い回し
  if (!_payjp)    _payjp = Payjp(pk);
  if (!_elements) _elements = _payjp.elements();

  // 新規Elementsを用意してマウント
  const numberEl = _elements.create('cardNumber');
  const expiryEl = _elements.create('cardExpiry');
  const cvcEl    = _elements.create('cardCvc');

  numberEl.mount('#number-form');
  expiryEl.mount('#expiry-form');
  cvcEl.mount('#cvc-form');

  // 送信時ハンドラ
  const onSubmit = async (e) => {
    e.preventDefault();
    const btn = form.querySelector('input[type="submit"],button[type="submit"]');
    if (btn) btn.disabled = true;

    try {
      // カード番号Elementからトークン生成
      const { id, error } = await _payjp.createToken(numberEl);

      // ---- ここがエラー時の処理（要件どおり反映）----
      if (error) {
        if (btn) btn.disabled = false;

        // 空トークンを必ず送って、Rails側で "Token can't be blank" を出す
        let tokenInput = document.getElementById('token');
        if (!tokenInput) {
          tokenInput = document.createElement('input');
          tokenInput.type = 'hidden';
          tokenInput.name = 'order_address[token]';
          tokenInput.id   = 'token';
          form.appendChild(tokenInput);
        }
        tokenInput.value = '';

        // 再帰防止のため一旦ハンドラを外してから送信 → 422で戻り、エラー表示
        form.removeEventListener('submit', onSubmit);
        form.submit();
        return;
      }
      // ---- /エラー時 ----

      // 成功：hiddenにトークンを詰めて送信
      let tokenInput = document.getElementById('token');
      if (!tokenInput) {
        tokenInput = document.createElement('input');
        tokenInput.type = 'hidden';
        tokenInput.name = 'order_address[token]';
        tokenInput.id   = 'token';
        form.appendChild(tokenInput);
      }
      tokenInput.value = id;

      // 再帰防止してから通常送信
      form.removeEventListener('submit', onSubmit);
      form.submit();
    } finally {
      // 必要ならここでローディング解除など
    }
  };

  form.addEventListener('submit', onSubmit);
  form._payjpOnSubmit = onSubmit;
}
