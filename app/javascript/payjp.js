(() => {
  // 名前空間（他コードと衝突しないように）
  const NS = (window.PayjpMount ||= {});
  let payjp = null;
  let elements = null;

  // Turboイベントにフック
  document.addEventListener('turbo:load', mount);
  document.addEventListener('turbo:render', mount);
  document.addEventListener('turbo:before-cache', cleanup);

  // 公開：他から必要なら呼べるように
  NS.mount = mount;
  NS.cleanup = cleanup;

  function cleanup() {
    const form = document.getElementById('charge-form');
    if (form && form._payjpOnSubmit) {
      form.removeEventListener('submit', form._payjpOnSubmit);
      form._payjpOnSubmit = null;
    }
    // Elements のホストだけ空に（他DOMは触らない）
    ['number-form', 'expiry-form', 'cvc-form'].forEach((id) => {
      const host = document.getElementById(id);
      if (host) host.innerHTML = '';
    });
    // フラグを下ろす
    const f = document.getElementById('charge-form');
    if (f) f.dataset.payjpMounted = '0';
  }

  function mount() {
    const form = document.getElementById('charge-form');
    const numberHost = document.getElementById('number-form');
    const expiryHost = document.getElementById('expiry-form');
    const cvcHost    = document.getElementById('cvc-form');
    if (!form || !numberHost || !expiryHost || !cvcHost) return;

    // PAY.JP SDK / 公開鍵チェック（未読込なら何もしない＝他機能に影響なし）
    const pk = document.querySelector('meta[name="payjp-public-key"]')?.content;
    if (!pk || !window.Payjp) return;

    // 二重マウント防止（Turboで複数回呼ばれてもOK）
    if (form.dataset.payjpMounted === '1') return;

    // 既存をきれいにしてから再マウント
    cleanup();

    if (!payjp)    payjp = Payjp(pk);
    if (!elements) elements = payjp.elements();

    const numberEl = elements.create('cardNumber');
    const expiryEl = elements.create('cardExpiry');
    const cvcEl    = elements.create('cardCvc');

    numberEl.mount('#number-form');
    expiryEl.mount('#expiry-form');
    cvcEl.mount('#cvc-form');

    const onSubmit = async (e) => {
      e.preventDefault();

      // 他のsubmitハンドラには触らない方針だが、
      // 二重送信は避けたいのでボタンだけ保守的に無効化
      const btn = form.querySelector('input[type="submit"],button[type="submit"]');
      if (btn) btn.disabled = true;

      try {
        const { id, error } = await payjp.createToken(numberEl);

        // エラー時：空トークンを付けて送信 → Rails側で "Token can't be blank" を表示
        if (error) {
          if (btn) btn.disabled = false;
          ensureTokenInput(form).value = '';
          form.removeEventListener('submit', onSubmit);
          form.submit();
          return;
        }

        // 成功：hiddenにトークンを詰めて送信
        ensureTokenInput(form).value = id;
        form.removeEventListener('submit', onSubmit);
        form.submit();
      } finally {
        // 必要に応じてローディング解除などをここで
      }
    };

    form.addEventListener('submit', onSubmit);
    form._payjpOnSubmit = onSubmit;
    form.dataset.payjpMounted = '1';
  }

  function ensureTokenInput(form) {
    let tokenInput = document.getElementById('token');
    if (!tokenInput) {
      tokenInput = document.createElement('input');
      tokenInput.type = 'hidden';
      tokenInput.name = 'order_address[token]'; // ← strong paramsと一致
      tokenInput.id   = 'token';
      form.appendChild(tokenInput);
    }
    return tokenInput;
  }
})();
