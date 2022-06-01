class Collection {
  constructor(type, defaults = []) {
    this.type = type;
    this.models = [];
    this.nextId = 1;
    defaults.forEach(params => {
      const model = new type(params.validationData);
      Object.keys(params).forEach(key => {
        if(key !== "validationData") {
          model.set(key, params[key] || '')
        }
      });
      this.add(model);
    });
  }

  reset(models) {
    const withIndex = models.map((m, i) => m._id = i + 1 && m)
    this.models = models;
  }

  add(model) {
    if (model instanceof this.type) {
      model._id = this._nextId();
      this.models.push(model);
    } else {
      console.warn(`invalid model for '${this.type}' collection:`, model);
    }
  }

  remove(id) {
    this.models = this.models.filter(m => m._id !== id);
  }

  validate() {
    this.done = this.models.map(m => m.validate()).every(t => t);
  }

  hasErrors() {
    return this.models.some(m => m.hasErrors());
  }

  _nextId() {
    const next = this.nextId;
    this.nextId += 1;
    return next;
  }

  filter(callback) {
    return this.models.filter(callback);
  }

  map(callback) {
    return this.models.map(callback);
  }

  get length() {
    return this.models.length;
  }

  set(index, field, value) {
    const shouldValidate = this.hasErrors();
    this.models[index].set(field, value);
    if (shouldValidate) this.validate();
  }

  data() {
    return this.models.map(m => m.data());
  }
}

export default Collection;
