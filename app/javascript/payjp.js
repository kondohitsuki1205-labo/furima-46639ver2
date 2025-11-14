// app/javascript/payjp.js
let _payjp = null;

document.addEventListener('turbo:load',  mountPayjp);
document.addEventListener('turbo:render', mountPayjp);
document.addEventListener('turbo:before-cache', cleanupPayjp);

function cleanupPayjp() {
  const form = document.getElementById('charge-form');
  if (!form) return;

  // 送信ハンドラ解除
  if (form._payjpOnSubmit) {
    form.removeEventListener('submit', form._payjpOnSubmit);
    form._payjpOnSubmit = null;
  }

  // Elements のアンマウント（ホストを空に）
  ['number-form', 'expiry-form', 'cvc-form'].forEach((id) => {
    const host = document.getElementById(id);
    if (host) host.innerHTML = '';
  });

  // トークンの初期化
  const tokenInput = document.getElementById('token');
  if (tokenInput) tokenInput.value = '';

  // フラグ類を初期化
  form.dataset.payjpTries = '';
  form.dataset.payjpReady = '0';
  form._payjpNumberEl = null;
}

async function mountPayjp() {
  const form = document.getElementById('charge-form');
  if (!form) return;

  // 1ページ滞在中、重複初期化は避ける（ただしログイン直後などで未準備なら後続で再トライ）
  form.dataset.payjpReady = form.dataset.payjpReady || '0';

  const tries = parseInt(form.dataset.payjpTries || '0', 10);
  if (tries > 120) return; // 約6秒（50ms * 120）

  const pk = document.querySelector('meta[name="payjp-public-key"]')?.content;

  // SDK or 公開鍵が未準備なら少し待って再挑戦
  if (!pk || !window.Payjp) {
    form.dataset.payjpTries = String(tries + 1);
    setTimeout(mountPayjp, 50);
    return;
  }

  // ここから初期化
  if (!_payjp) _payjp = Payjp(pk);

  const numberHost = document.getElementById('number-form');
  const expiryHost = document.getElementById('expiry-form');
  const cvcHost    = document.getElementById('cvc-form');
  if (!numberHost || !expiryHost || !cvcHost) return;

  // ホストに中身が残っているケース（理論上 before-cache で空になる想定だが保険）
  if ((numberHost.children.length || expiryHost.children.length || cvcHost.children.length) && !form._payjpNumberEl) {
    // 一旦空にしてから作り直す
    [numberHost, expiryHost, cvcHost].forEach((el) => (el.innerHTML = ''));
  }

  // Elements を作り直し、3分割で mount
  const elements = _payjp.elements();
  const numberEl = elements.create('cardNumber');
  const expiryEl = elements.create('cardExpiry');
  const cvcEl    = elements.create('cardCvc');

  numberEl.mount('#number-form');
  expiryEl.mount('#expiry-form');
  cvcEl.mount('#cvc-form');

  // submit ハンドラの取り付け（numberEl をフォームに保持して再利用）
  form._payjpNumberEl = numberEl;
  attachSubmitHandler(form);

  form.dataset.payjpReady = '1';
  form.dataset.payjpTries = '';
}

function attachSubmitHandler(form) {
  // 既存があれば外す（重複送信防止）
  if (form._payjpOnSubmit) {
    form.removeEventListener('submit', form._payjpOnSubmit);
    form._payjpOnSubmit = null;
  }

  const handler = async (e) => {
    e.preventDefault();
    const btn = form.querySelector('input[type="submit"],button[type="submit"]');
    if (btn) btn.disabled = true;

    try {
      const numberEl = form._payjpNumberEl; // mount 時に保存した Element
      const { id, error } = await _payjp.createToken(numberEl);

      // hidden のトークン要素を確保
      let tokenInput = document.getElementById('token');
      if (!tokenInput) {
        tokenInput = document.createElement('input');
        tokenInput.type = 'hidden';
        tokenInput.name = 'order_address[token]';
        tokenInput.id   = 'token';
        form.appendChild(tokenInput);
      }

      if (error) {
        // 失敗時もサーバへ投げて 422 でエラーパーツ表示
        if (btn) btn.disabled = false;
        tokenInput.value = ''; // 空で送ってモデル側の "Token can't be blank" を出す
        form.removeEventListener('submit', handler);
        form._payjpOnSubmit = null;
        form.submit();
        return;
      }

      // 成功：トークンを詰めて通常 submit
      tokenInput.value = id;
      form.removeEventListener('submit', handler);
      form._payjpOnSubmit = null;
      form.submit();
    } finally {
      // 成功/失敗の双方で submit 済みのため、ここでボタン解放は不要
    }
  };

  form.addEventListener('submit', handler);
  form._payjpOnSubmit = handler;
}
