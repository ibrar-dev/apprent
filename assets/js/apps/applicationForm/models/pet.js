import Model from './model';

class Pet extends Model {}

Pet.fields = [
  {
    field: 'name',
    defaultValue: '',
    validation: (type) => type.length > 1 ? true : 'pet_name_error'
  },
  {
    field: 'breed',
    defaultValue: '',
    validation: (type) => type.length > 2 ? true : 'pet_breed_error'
  },
  {
    field: 'type',
    defaultValue: '',
    validation: (type) => type.length > 2 ? true : 'pet_type_error'
  },
  {
    field: 'weight',
    defaultValue: 0,
    validation: (weight) => weight > 0 ? true : 'pet_weight_error'
  }
];

export default Pet;