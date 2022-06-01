import Model from './model';
import Address from './address';

class History extends Model {}

History.fields = [
  {
    field: 'address',
    defaultValue: window.APPLICATION_JSON ? '' : Address,
    validation: (address) => {
      if (window.APPLICATION_JSON) {
        return address.length > 3 ? true : 'address_error';
      }
      address.validate();
      return address.errors;
    }
  },
  {
    field: 'landlord_name',
    defaultValue: '',
    validation: (landlord_name, history) => {
      return !history.rent || landlord_name.length > 2 ? true : 'll_name_error'
    }
  },
  {
    field: 'landlord_phone',
    defaultValue: '',
    validation: (landlord_phone, history) => {
      return !history.rent || landlord_phone.match(/\(\d{3}\) \d{3}-\d{4}/)  ? true : 'll_num_error'
    }
  },
  {
    field: 'landlord_email',
    defaultValue: '',
    validation: () => true
  },
  {
    field: 'rent',
    defaultValue: false
  },
  {
    field: 'rental_amount',
    defaultValue: 0,
    validation: (rental_amount, history) => {
      return !history.rent || rental_amount > 0 ? true : 'rent_error'
    }
  },
  {
    field: 'residency_length',
    defaultValue: '',
    validation: () => true
  },
  {
    field: 'current',
    defaultValue: true,
    validation: (current) => current === undefined ? 'current_error': true
  }
];

export default History;
