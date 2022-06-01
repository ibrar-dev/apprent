import React from 'react';
import {Row, Col} from 'reactstrap';
import moment from 'moment';
import Calendar from '../../../components/calendar';
import Event from './event';
import Day from './day';
import actions from '../actions';
import MaintenanceSnapshot from './maintenanceSnapshot';

const displays = {
  move_out(data) {
    return `Move Out`
  },
  move_in(data) {
    return `Move In`
  },
  showing(data) {
    return `Showing`
  },
  memo(data) {
    return `Memo`
  },
  resident_event(data) {
    return 'Resident Event'
  }
};

class DashboardCalendar extends React.Component {
  state = {selectedDate: moment().startOf('day').toDate()};

  selectDate(date) {
    this.setState({...this.state, selectedDate: date, selectedEvent: null});
    actions.fetchDailySnapshot(date);
  }

  selectEvent(e) {
    this.setState({...this.state, selectedEvent: e});
  }

  render() {
    const {events, maintenanceSnapshot} = this.props;
    const {selectedDate, selectedEvent} = this.state;
    const currentEvents = events[moment(selectedDate).format('YYYY-MM-DD')] || [];
     return <Row style={{paddingLeft:"1.5%", paddingRight:"1.5%", height:"791px"}}>
      <Col sm={10} md={9}>
        <Calendar onSelectDate={this.selectDate.bind(this)}
                  onSelectEvent={this.selectEvent.bind(this)}
                  events={events}
                  display={displays}
                  selectedEvent={selectedEvent}
                  allowPast={true}
                  selectedDate={selectedDate}
        />
      </Col>
      <Col sm={2} md={3}>
        {maintenanceSnapshot.length >= 1 && <MaintenanceSnapshot maintenanceSnapshot={maintenanceSnapshot} />}
        {selectedEvent && <Event event={selectedEvent}/>}
        {!selectedEvent && <Day date={selectedDate} events={currentEvents}/>}
      </Col>
    </Row>;
  }
}

export default DashboardCalendar;