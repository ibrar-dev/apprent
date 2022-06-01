class ClearUpload {
  constructor() {
    this.initialize();
  }

  initialize() {
    this._clear = new Promise((resolve) => this._resolve = resolve);
  }

  clear() {
    return this._clear;
  }

  resolve() {
    this._resolve();
    this.initialize();
  }
}

export default new ClearUpload();