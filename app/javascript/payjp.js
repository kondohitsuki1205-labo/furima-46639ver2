// app/javascript/payjp.js

// --- クリーンアップ（送信ハンドラ解除 & ホストを空に & token初期化）---
function cleanupPayjp() {
  const form = document.getElementById('charge-form');
  if (form && form._payjpOnSubmit) {
    form.removeEventListener('submit', form._payjpOnSubmit);
    form._payjpOnSubmit = null;
  }
  ['number-form','expiry-form','cvc-form'].forEach((id) => {
    const host = document.getElementById(id);
    if (host) host.innerHTML = '';
  });
  const token = document.getElementById('token');
  if (token) token.value = '';
}

// Turbo キャッシュ保存前（通常遷移）
document.addEventListener('turbo:before-cache', cleanupPayjp);

// ★ログアウトなどの非GET遷移開始時にも確実にお掃除
document.addEventListener('turbo:visit', cleanupPayjp);

// ページ描画後にElementsをマウント
document.addEventListener('turbo:load',  mountPayjp);
document.addEventListener('turbo:render', mountPayjp);

function mountPayjp() {
  const form = document.getElementById('charge-form');
  if (!form) return;

  // 二重送信防止：既存ハンドラを解除
  if (form._payjpOnSubmit) {
    form.removeEventListener('submit', form._payjpOnSubmit);
    form._payjpOnSubmit = null;
  }

  // ホストを必ず空に（preview→renderでも安定）
  ['number-form','expiry-form','cvc-form'].forEach((id) => {
    const host = document.getElementById(id);
    if (host) host.innerHTML = '';
  });

  const pk = document.querySelector('meta[name="payjp-public-key"]')?.content;
  if (!pk || !window.Payjp) return;

  // ★毎回フレッシュにインスタンス化（再利用はしない）
  const payjp    = Payjp(pk);
  const elements = payjp.elements();

  // DOM確定後にmount（タイミング依存を避ける）
  requestAnimationFrame(() => {
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
        const { id, error } = await payjp.createToken(numberEl);

        if (error) {
          // エラーでもフォーム送信して Rails 側のエラー表示を出す（token空）
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

        form.removeEventListener('submit', onSubmit);
        form.submit();
      } finally {
        // ローディング解除など必要ならここで
      }
    };

    form.addEventListener('submit', onSubmit);
    form._payjpOnSubmit = onSubmit;
  });
}
