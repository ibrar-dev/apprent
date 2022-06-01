import React from 'react';
import {DateTimePicker} from 'react-widgets';
import Moment from 'moment'
import momentLocalizer from 'react-widgets-moment';

Moment.locale('en');
momentLocalizer();

const genericMidnight = () => {
  return new Date(1970, 0, 1);
};

const parseTime = (date) => {
  return {hour: date.getHours(), minute: date.getMinutes()}
};

class TimePicker extends React.Component {
  state = {time: genericMidnight()};

  handleTimeSet(time) {
    this.setState({time});
    this.props.onChange(parseTime(time));
  }

  render() {
    const {time} = this.state;
    return <DateTimePicker date={false}
                           onChange={this.handleTimeSet.bind(this)}
                           value={time}/>;
  }
}

export default TimePicker;