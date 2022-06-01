import React from 'react';
import Calendar from '../../../../components/calendar';

class Month extends React.Component {
  state = {};

  render() {
    const {showings, selectDate} = this.props;
    return <Calendar onSelectDate={selectDate}
              onSelectEvent={() => {}}
              events={showings}
              selectedEvent={null}/>;
  }
}

export default Month;