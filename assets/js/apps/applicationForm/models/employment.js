import Model from './model';
import Address from './address';

class Employment extends Model {
}

Employment.fields = [
  {
    field: 'occupant_index',
    defaultValue: 1,
    validation: (index) => index > 0 ? true : 'choose_occupant'
  },
  {
    field: 'address',
    defaultValue: window.APPLICATION_JSON ? '' : Address,
    validation: (address) => {
      if (window.APPLICATION_JSON) return address.length > 3 ? true : 'address_error'
      address.validate();
      return address.errors;
    }
  },
  {
    field: 'duration',
    defaultValue: '',
    validation: (duration) => duration.length > 2 ? true : 'employment_duration_error'
  },
  {
    field: 'employer',
    defaultValue: '',
    validation: (employer) => employer.length > 3 ? true : 'employment_name_error'
  },
  {
    field: 'phone',
    defaultValue: '',
    validation: (phone) => phone.match(/\(\d\d\d\) \d\d\d-\d\d\d\d/) ? true : 'employment_num_error'
  },
  {
    field: 'email',
    defaultvalue: '',
    validation: (email) => email.match(/^.+@[^.].*\.[a-z]{2,}$/) ? true : 'email_error'
  },
  {
    field: 'supervisor',
    defaultValue: '',
    validation: (supervisor) => supervisor.length > 3 ? true : 'employment_super_error'
  },
  {
    field: 'salary',
    defaultValue: 0,
    validation: (salary) => salary > 10 ? true : 'salary_error'
  },
  {
    field: 'current',
    defaultValue: true,
    validation: (current) => current === undefined ? 'current_error' : true
  }
];

export default Employment;
