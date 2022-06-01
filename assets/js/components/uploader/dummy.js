class Dummy {
  upload() {
    const _this = this;
    return {
      then(func) {
        func();
        return _this;
      },
      catch() {}
    }
  }
}

export default Dummy;