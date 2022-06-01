import Model from './model';

class Address extends Model {
  toString() {
    if (this.hasErrors()) return 'invalid_address';
    const unit = this.unit ? ` Unit ${this.unit}` : '';
    return `${this.address}${unit}, ${this.city} ${this.state} ${this.zip}`;
  }

  fromString(string) {

  }
}

Address.fields = [
  {
    field: 'address',
    defaultValue: '',
    validation: (address) => address.length > 2 ? true : 'address_error'
  },
  {
    field: 'city',
    defaultValue: '',
    validation: (city) => city.length > 2 ? true : 'city_error'
  },
  {
    field: 'state',
    defaultValue: '',
    validation: (state) => state.length === 2 ? true : 'state_error'
  },
  {
    field: 'zip',
    defaultValue: '',
    validation: (zip) => zip.length > 4 ? true : 'zip_error'
  },
  {
    field: 'unit',
    defaultValue: '',
    validation: () => true
  }
];

export default Address;