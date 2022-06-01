import React from 'react';
import {Input} from 'reactstrap';

const periodKey = {AM: 0, PM: 12};
const counterArray = [...new Array(12)];

const convertHours = (int, factor) => {
  const base = Math.floor(int / 60) - factor;
  return base > 0 ? base : 12;
};
const convertMins = int => int % 60;
const valid = (type, val) => {
  const max = type === 'hours' ? 12 : 59;
  const min = type === 'hours' ? 1 : 0;
  return val >= min && val <= max;
};


class TimeInput extends React.Component {
  state = {period: this.props.time > (12 * 60) ? 'PM' : 'AM'};

  changePeriod({target: {value}}) {
    this.setState({...this.state, period: value});
    const timeChange = value === 'PM' ? (12 * 60)  : (-12 * 60);
    const {onChange, name, time} = this.props;
    onChange({target: {name, value: time + timeChange}});
  }

  change(type, {target: {value}}) {
    if (!valid(type, value)) return;
    const {period} = this.state;
    const {onChange, name, time} = this.props;
    let val = null;
    const num = parseInt(value);
    const factor = periodKey[period] + (num === 12 ? -12 : 0);
    if (type === 'hours') {
      val = convertMins(time) + ((num + factor) * 60);
    } else {
      val = time - convertMins(time) + num;
    }
    onChange({target: {name, value: val}});
  }

  render() {
    const {period} = this.state;
    const {time, label} = this.props;
    return <div className="d-flex">
      <div className="w-25 d-flex justify-content-end align-items-center p-2">
        {label}:
      </div>
      <div className="w-25 p-1">
        <Input type="select"
               value={convertHours(time, periodKey[period])}
               onChange={this.change.bind(this, 'hours')}>
          {counterArray.map((b, index) => {
            return <option key={index} value={index + 1}>
              {index + 1}
            </option>
          })}
        </Input>
      </div>
      <div className="w-25 p-1">
        <Input type="select"
               value={convertMins(time)}
               onChange={this.change.bind(this, 'minutes')}>
          {counterArray.map((b, index) => {
            return <option key={index} value={index * 5}>
              {`0${index * 5}`.replace(/\d(\d\d)/, '$1')}
            </option>
          })}
        </Input>
      </div>
      <div className="p-1">
        <Input type="select" value={period} onChange={this.changePeriod.bind(this)}>
          <option value="AM">AM</option>
          <option value="PM">PM</option>
        </Input>
      </div>
    </div>
  }
}

export default TimeInput;