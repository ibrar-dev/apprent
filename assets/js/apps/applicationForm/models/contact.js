import Model from './model';

class Contact extends Model {}

const applicantPhones = (validationData) => {
  const numbers = []
  validationData.occupants.models.forEach((occupant) => {
    const {cell_phone, home_phone, work_phone} = occupant;
      if(!!work_phone) numbers.push(work_phone)
      if(!!home_phone) numbers.push(home_phone)
      if(!!cell_phone) numbers.push(cell_phone)
  });
  return numbers
}

Contact.fields = [
  {
    field: 'name',
    defaultValue: '',
    validation: (name) => name.length > 2 ? true : 'contact_name_error'
  },
  {
    field: 'phone',
    defaultValue: '',
    validation: (phone, model) => {
      return phone.match(/\(\d\d\d\) \d\d\d-\d\d\d\d/) ? true : 'contact_phone_error'
    }
  },
  {
    field: 'email',
    defaultvalue: '',
    validation: (email) => email.match(/^.+@[^.].*\.[a-z]{2,}$/) ? true : 'email_error'
  },
  {
    field: 'relationship',
    defaultValue: '',
    validation: (relationship) => relationship.length > 2 ? true : 'contact_relation_error'
  }
];

export default Contact;
