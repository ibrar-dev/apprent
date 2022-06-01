import Model from './model';

class Income extends Model {
  constructor() {
    super();
    Object.defineProperty(this, 'id', {
      get: () => this._data.id,
      set: (value) => {
        this._data.id = value;
        if (value) this.present = true;
        if (this.hasErrors()) this.validate();
      }
    });
    Object.defineProperty(this, 'present', {
      get: () => this._data.present,
      set: (value) => {
        this._data.present = value;
        if (!value) this.id = '';
        if (this.hasErrors()) this.validate();
      }
    });
  }
}

Income.fields = [
  {
    field: 'salary',
    defaultValue: 0,
    validation: (salary, income) => !income.present || salary > 0 ? true : 'salary_error'
  },
  {
    field: 'description',
    defaultValue: '',
    validation: (description, income) => !income.present || description.length > 2 ? true : 'description_error'
  },
  {
    field: 'present',
    defaultValue: false,
    configurable: true,
    validation: () => true
  }
];

export default Income;