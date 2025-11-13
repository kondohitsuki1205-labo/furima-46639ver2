document.addEventListener('turbo:load',  mountPayjp);
document.addEventListener('turbo:render', mountPayjp);

function mountPayjp() {
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
  form.dataset.payjpBound = '0';

  const numberHost = document.getElementById('number-form');
  if (!numberHost) return;

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

  const onSubmit = async (e) => {
    e.preventDefault();
    const btn = form.querySelector('input[type="submit"],button[type="submit"]');
    if (btn) btn.disabled = true;

    try {
      const { id, error } = await payjp.createToken(numberEl);

      if (error) {
        if (btn) btn.disabled = false;
        form.removeEventListener('submit', onSubmit);
        form.submit();
        return;
      }

      let tokenInput = document.getElementById('token');
      if (!tokenInput) {
        tokenInput = document.createElement('input');
        tokenInput.type  = 'hidden';
        tokenInput.name  = 'order_address[token]';
        tokenInput.id    = 'token';
        form.appendChild(tokenInput);
      }
      tokenInput.value = id;

      form.removeEventListener('submit', onSubmit);
      form.submit();
    } finally {
    }
  };

  form.addEventListener('submit', onSubmit);
  form._payjpOnSubmit = onSubmit;
  form.dataset.payjpBound = '1';
}
