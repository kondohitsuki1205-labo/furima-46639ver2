let _payjp = null;
let _elements = null;

document.addEventListener('turbo:load', mountPayjp);
document.addEventListener('turbo:render', mountPayjp);

function mountPayjp() {
  const form = document.getElementById('charge-form');
  if (!form) return;

  // --- 重複バインド対策：前回の submit ハンドラを外す ---
  if (form._payjpOnSubmit) {
    form.removeEventListener('submit', form._payjpOnSubmit);
    form._payjpOnSubmit = null;
  }

  // --- 既に mount 済みの Elements があれば unmount して空に ---
  const hosts = ['number-form', 'expiry-form', 'cvc-form'];
  hosts.forEach((id) => {
    const host = document.getElementById(id);
    if (host) host.innerHTML = '';
  });

  // --- 公開鍵 & ライブラリ確認 ---
  const pk = document.querySelector('meta[name="payjp-public-key"]')?.content;
  if (!pk || !window.Payjp) return;

  // --- Payjp / Elements を1度だけ作り、以後は再利用 ---
  if (!_payjp) _payjp = Payjp(pk);
  if (!_elements) _elements = _payjp.elements();

  // --- 新しい Elements を生成して mount ---
  const numberEl = _elements.create('cardNumber');
  const expiryEl = _elements.create('cardExpiry');
  const cvcEl    = _elements.create('cardCvc');

  numberEl.mount('#number-form');
  expiryEl.mount('#expiry-form');
  cvcEl.mount('#cvc-form');

  // フォーム送信時の処理
  const onSubmit = async (e) => {
    e.preventDefault();
    const btn = form.querySelector('input[type="submit"],button[type="submit"]');
    if (btn) btn.disabled = true;

    try {
      // Elements からトークン生成
      const { id, error } = await _payjp.createToken(numberEl);

      if (error) {
        // ★カードエラーはサーバへ送らない（422防止）。
        //   ここで入力継続できるようにするだけ。
        if (btn) btn.disabled = false;
        // 既存トークンは無効化
        const tokenInput = document.getElementById('token');
        if (tokenInput) tokenInput.value = '';
        console.warn('[PAYJP] card error:', error);
        return;
      }

      // hidden を用意してトークンを格納
      let tokenInput = document.getElementById('token');
      if (!tokenInput) {
        tokenInput = document.createElement('input');
        tokenInput.type = 'hidden';
        tokenInput.name = 'order_address[token]';
        tokenInput.id   = 'token';
        form.appendChild(tokenInput);
      }
      tokenInput.value = id;

      // 送信ハンドラを一旦外してから通常 submit
      form.removeEventListener('submit', onSubmit);
      form.submit();
    } finally {
      // 何もしない（必要ならここでローディング解除等）
    }
  };

  form.addEventListener('submit', onSubmit);
  form._payjpOnSubmit = onSubmit;
}
