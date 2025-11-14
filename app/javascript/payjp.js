let _payjp = null;
let _elements = null;

document.addEventListener('turbo:load',  mountPayjp);
document.addEventListener('turbo:render', mountPayjp);

// Turboがページをキャッシュする直前に、埋め込みDOMを空にしないと
// 復元時（preview or render）に「既にインスタンス化されています」→未描画 になりがち
document.addEventListener('turbo:before-cache', () => {
  const form = document.getElementById('charge-form');
  if (form && form._payjpOnSubmit) {
    form.removeEventListener('submit', form._payjpOnSubmit);
    form._payjpOnSubmit = null;
  }
  ['number-form','expiry-form','cvc-form'].forEach((id) => {
    const host = document.getElementById(id);
    if (host) host.innerHTML = '';
  });
  // hidden token もいったん空に（エラー後の戻りで残骸を避ける）
  const token = document.getElementById('token');
  if (token) token.value = '';
});

function mountPayjp() {
  const form = document.getElementById('charge-form');
  if (!form) return;

  // 直前のsubmitハンドラを外す（重複送信回避）
  if (form._payjpOnSubmit) {
    form.removeEventListener('submit', form._payjpOnSubmit);
    form._payjpOnSubmit = null;
  }

  // preview→render の順で複数回呼ばれてもOKにするため、必ずホストを空に
  ['number-form','expiry-form','cvc-form'].forEach((id) => {
    const host = document.getElementById(id);
    if (host) host.innerHTML = '';
  });

  const pk = document.querySelector('meta[name="payjp-public-key"]')?.content;
  if (!pk || !window.Payjp) return;

  if (!_payjp)    _payjp = Payjp(pk);
  if (!_elements) _elements = _payjp.elements();

  // DOM反映直後にmountしないと、たまにホスト未準備のタイミングで失敗することがあるので rAF で次フレームに回す
  requestAnimationFrame(() => {
    const numberEl = _elements.create('cardNumber');
    const expiryEl = _elements.create('cardExpiry');
    const cvcEl    = _elements.create('cardCvc');

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
          // ▼バリデーション表示のために空トークンを送る（「Token can't be blank」）
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
          form.submit();
          return;
        }

        // 成功時：hidden に格納して送信
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
        // 必要ならここでローディング解除など
      }
    };

    form.addEventListener('submit', onSubmit);
    form._payjpOnSubmit = onSubmit;
  });
}
