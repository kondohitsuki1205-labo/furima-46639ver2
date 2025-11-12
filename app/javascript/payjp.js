document.addEventListener('turbo:load', mountPayjp);

function mountPayjp() {
  const form = document.getElementById('charge-form');
  if (!form) return;
  if (form.dataset.payjpBound === '1') return;
  form.dataset.payjpBound = '1';

  const numberHost = document.getElementById('number-form');
  if (!numberHost || numberHost.children.length) return;

  const pk = document.querySelector('meta[name="payjp-public-key"]')?.content;
  if (!pk || !window.Payjp) return;

  const payjp = Payjp(pk);
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

      document.getElementById('token').value = id;
      form.removeEventListener('submit', onSubmit);
      form.submit();
    } finally {
    }
  };

  form.addEventListener('submit', onSubmit);
}
