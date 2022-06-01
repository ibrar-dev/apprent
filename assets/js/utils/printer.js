const styling = `@media only print {body > :not(#printing-area), body > :not(#printing-area) * {display: none !important;}}@media only screen {#printing-area: display: none;}`;


class ElementPrinter {
  constructor(element) {
    this._element = document.createElement('div');
    this._element.id = 'printing-area';
    this._element.innerHTML = element.outerHTML;
    this._style = document.createElement('style');
    this._style.innerHTML = styling;
    new Promise((resolve) => this._resolve = resolve).then(this._cleanup.bind(this));
    if (window.matchMedia) {
      this._mediaQueryList = window.matchMedia('print');
      this._mediaQueryList.addListener(this._listener.bind(this));
    }
  }

  setStyles(styles) {
    this._style.innerHTML = this._style.innerHTML + styles.map(s => `#printing-area ${s}`).join('');
    return this;
  }

  print() {
    document.body.appendChild(this._element);
    document.head.appendChild(this._style);
    print();
    return this;
  }

  then(callback) {
    this._callback = callback;
  }

  _cleanup() {
    document.head.removeChild(this._style);
    document.body.removeChild(this._element);
    this._mediaQueryList.removeListener(this._listener);
    this._callback && this._callback();
  }


  _listener(e) {
    if (this._printing && !e.matches) this._resolve();
    this._printing = e.matches;
  }
}

export default ElementPrinter;