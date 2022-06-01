import React from 'react';
import DatePicker from '../../../../components/datePicker';
import moment from 'moment';

export default (name, value, error, options, label) => {
  const handleChange = (name, {target: {value: date}}) => {
    options.component.editField({target: {value: date.format('YYYY-MM-DD'), name}});
  };
  return <div className="labeled-box">
  <DatePicker value={value}
                     name={name}
                     isOutsideRange={day => {
                       const violatesMin = options.min ? moment().add(options.min, 'years').isAfter(day) : false;
                       const violateMax = options.max ? moment().add(options.max, 'years').isBefore(day) : false;
                       return violateMax || violatesMin;
                     }}
    // openToDate={moment().add(options.openTo, 'years').toDate()}
                     className="py-1 pr-4"
                     placeholder={''}
                     invalid={error}
                     onChange={handleChange.bind(this, name)}/>
    <div className="labeled-box-label">{label}</div>
  </div>
};