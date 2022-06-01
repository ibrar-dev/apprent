import Model from './model';
import moment from 'moment';

const phoneValidate = (_phone, p) => {
  const phoneFields = ['home_phone', 'work_phone', 'cell_phone'];
  for (let i = 0; i < phoneFields.length; i++) {
    if (p[phoneFields[i]].match(/\(\d\d\d\) \d\d\d-\d\d\d\d/)) return true;
  }
  return 'phone_error';
};

const nameValidate = (name) => {
  name = name.trim().split(" ")
  const first_name = name[0]
  const last_name = name[name.length-1]
  if (name.length >= 2 && first_name.length >= 2 && last_name.length >= 2){
    return true;
  }
  else {
    return 'name_error';
  }
}

class Person extends Model {
  isAdult() {
    const dob = moment(this.dob);
    const start = moment().subtract(18, 'years');
    return dob.isBefore(start);
  }
}

Person.fields = [
  {
    field: 'full_name',
    defaultValue: '',
    validation: nameValidate
  },
  {
    field: 'ssn',
    defaultValue: '',
    validation: (ssn) => ssn.length === 11 && ssn.match(/^\d\d\d-\d\d-\d\d\d\d$/) ? true : 'ssn_error'
  },
  {
    field: 'email',
    defaultValue: '',
    validation: (email) => email.match(/^.+@[^.].*\.[a-z]{2,}$/) ? true : 'email_error'
  },
  {
    field: 'home_phone',
    defaultValue: '',
    validation: phoneValidate
  },
  {
    field: 'work_phone',
    defaultValue: '',
    validation: phoneValidate
  },
  {
    field: 'cell_phone',
    defaultValue: '',
    validation: phoneValidate
  },
  {
    field: 'dob',
    defaultValue: '',
    validation: (dob, {status}) => {
      const date = moment(dob);
      if (!date.isValid()) return 'invalid_dob';
      if (status !== 'Lease Holder') return true;
      const latestDob = moment().subtract(18, 'years');
      return date.isBefore(latestDob) ? true : 'too_young'
    }
},
  {
    field: 'dl_number',
    defaultValue: '',
    validation: (dl_number) => dl_number.length > 3 ? true : 'license_error'
  },
  {
    field: 'dl_state',
    defaultValue: '',
    validation: (state) => state.length === 2 ? true : 'license_state_error'
  },
  {
    field: 'status',
    defaultValue: '',
    validation: (status) => status.length > 2 ? true : 'status_error'
  }
];

export default Person;
