import Model from './model';

class Vehicle extends Model {}

Vehicle.fields = [
  {
    field: 'make_model',
    defaultValue: '',
    validation: (make_model) => make_model.length > 2 ? true : 'vehicle_mm_error'
  },
  {
    field: 'color',
    defaultValue: '',
    validation: (color) => color.length > 2 ? true : 'vehicle_color_error'
  },
  {
    field: 'license_plate',
    defaultValue: '',
    validation: (license_plate) => license_plate.length > 3  ? true : 'vehicle_license_error'
  },
  {
    field: 'state',
    defaultValue: '',
    validation: (state) => state.length === 2 ? true : 'vehicle_license_state_error'
  }
];

export default Vehicle;