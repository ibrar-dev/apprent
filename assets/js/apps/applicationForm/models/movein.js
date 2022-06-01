import Model from './model';
import moment from 'moment';

class MoveIn extends Model {}

MoveIn.fields = [
  {
    field: 'expected_move_in',
    defaultValue: (window.PROSPECT_PARAMS || {}).move_in || '',
    validation: (date) => moment(date).isValid() ? true : 'movein_error'
  },
  {
    field: 'unit_id',
    defaultValue: '',
    validation: () => true
  },
  {
    field: 'floor_plan_id',
    defaultValue: '',
    validation: () => true
  }
];

export default MoveIn;