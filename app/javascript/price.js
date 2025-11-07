function mountPriceCalc() {
  const priceInput = document.getElementById("item-price");
  const feeSpan    = document.getElementById("add-tax-price");
  const profitSpan = document.getElementById("profit");
  if (!priceInput || !feeSpan || !profitSpan) return;

  const update = () => {
    const value = Number(priceInput.value);
    if (Number.isInteger(value)) {
      const fee = Math.floor(value * 0.1);
      const profit = value - fee;
      feeSpan.textContent = isFinite(fee) ? fee : 0;
      profitSpan.textContent = isFinite(profit) ? profit : 0;
    } else {
      feeSpan.textContent = 0;
      profitSpan.textContent = 0;
    }
  };

  priceInput.addEventListener("input", update);
  update(); // 初期表示
}

document.addEventListener("turbo:load", mountPriceCalc);
document.addEventListener("DOMContentLoaded", mountPriceCalc);