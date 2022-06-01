const idField = {
  field: 'id',
  defaultValue: '',
  configurable: true
};

class Model {
  constructor(validationData = null) {
    this.validationData = validationData;
    this._data = {};
    this._validations = [];
    this.errors = [];
    this.constructor.fields.concat([idField]).forEach(({field, configurable, defaultValue = '', validation = (() => true)}) => {
      if (typeof defaultValue === 'function') {
        this._data[field] = new defaultValue();
      } else {
        this._data[field] = defaultValue;
      }
      Object.defineProperty(this, field, {
        get: () => this._data[field],
        configurable,
        set: (value) => {
          this._data[field] = value;
          if (this.hasErrors()) this.validate();
        }
      });
      this._validations.push({field, validation});
    });
  }

  importObj(obj) {
    for (const key in obj) {
      if (obj.hasOwnProperty(key) && this.hasOwnProperty(key)) {
        this.set(key, obj[key]);
      }
    }
  }

  set(field, value) {
    if (this[field] === undefined || value === null) return;
    if (this[field].validate) {
      Object.keys(value).forEach((k) => {
        this[field].set(k, value[k]);
      });
    } else {
      this[field] = value;
    }
  }

  data() {
    const dataKeys = Object.keys(this._data);
    return dataKeys.reduce((retVal, key) => {
      if (typeof this[key].data === 'function') {
        retVal[key] = this[key].data();
      } else {
        retVal[key] = this[key];
      }
      return retVal;
    }, {});
  }

  hasErrors() {
    return Object.values(this.errors).length > 0;
  }

  validate() {
    this.errors = this._validations.reduce((errors, {field, validation}) => {
      const returnValue = validation(this._data[field], this);
      if (typeof returnValue === 'string' || Object.keys(returnValue).length > 0) {
        errors[field] = returnValue;
      }
      return errors;
    }, {});
    this.done = !this.hasErrors();
    return this.done;
  }
}

Model.fields = [];

export default Model;
