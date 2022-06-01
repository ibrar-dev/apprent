import React from 'react';
import moment from 'moment';
import {connect} from 'react-redux';
import EventGroup from './eventGroup';
import {Card, Row, Col, Container, Badge} from 'reactstrap';

class Calendar extends React.Component {
  constructor(props) {
    super(props);
    const today = new Date();
    this.state = {month: today.getMonth(), year: today.getFullYear()};
  }

  componentDidMount() {
    setTimeout(() => {
      const cells = document.querySelectorAll('.apprent-calendar td');
      for (let i = 0; i < cells.length; i++) {
        const cell = cells[i];
        cell.style.height = cell.offsetWidth + 'px';
      }
    }, 100);
  }

  daysToDisplay() {
    const {month, year} = this.state;
    const monthStart = (new Date(year, month, 1));
    const days = [monthStart];
    let startDay = monthStart.getDay();
    let currentDay = moment(monthStart);
    while (startDay > 0) {
      currentDay.subtract(1, 'day');
      days.unshift(currentDay.toDate());
      startDay = currentDay.toDate().getDay();
    }
    currentDay = moment(monthStart);
    while (startDay < 6 || currentDay.month() === month) {
      currentDay.add(1, 'day');
      days.push(currentDay.toDate());
      startDay = currentDay.toDate().getDay();
    }
    return days;
  }

  calendarRows() {
    const days = this.daysToDisplay();
    const rows = [];
    while (days.length > 0) {
      rows.push(days.splice(0, 7));
    }
    return rows;
  }

  selectDate(date, isDisabled) {
    if (isDisabled) {
      alert('This date is not available.');
      return
    }
    this.props.onSelectDate(date);
  }

  nextMonth() {
    const {month, year} = this.state;
    const nextMonth = moment([year, month, 2]).add(1, 'month').toDate();
    this.setState({...this.state, month: nextMonth.getMonth(), year: nextMonth.getFullYear()});
  }

  prevMonth() {
    const {month, year} = this.state;
    const nextMonth = moment([year, month, 2]).subtract(1, 'month').toDate();
    this.setState({...this.state, month: nextMonth.getMonth(), year: nextMonth.getFullYear()});
  }

  render() {
    const rows = this.calendarRows();
    const {selectedDate, events, display, selectedEvent, onSelectEvent, popover, allowPast, onSelectEventGroup} = this.props;
    const today = moment(new Date()).startOf('day');
    return <div className="apprent-calendar">
      <div style={{backgroundColor:"#f6f6f6"}} className="d-flex justify-content-between align-items-center heading p-2">
        <a onClick={this.prevMonth.bind(this)} className="ml-1">
          <i style={{color: "#3a3b42"}}className="fas fa-arrow-left"/>
        </a>
        <h3 className="m-0">{moment([2010, this.state.month]).format('MMMM')} {this.state.year}</h3>
        <a onClick={this.nextMonth.bind(this)} className="mr-1">
          <i style={{color:"#3a3b42"}} className="fas fa-arrow-right"/>
        </a>
      </div>
      <Card>
        <Container>
        <Row>
          <Col style={{backgroundColor:"#f6f6f6"}}>Sun</Col>
          <Col style={{backgroundColor:"#f6f6f6"}}>Mon</Col>
          <Col style={{backgroundColor:"#f6f6f6"}}>Tue</Col>
          <Col style={{backgroundColor:"#f6f6f6"}}>Wed</Col>
          <Col style={{backgroundColor:"#f6f6f6"}}>Thu</Col>
          <Col style={{backgroundColor:"#f6f6f6"}}>Fri</Col>
          <Col style={{backgroundColor:"#f6f6f6"}}>Sat</Col>
        </Row>
        {rows.map((row, index) => {
          return <Row key={index}>{row.map((day, index) => {
            const momentDay = moment(day);
            const key = momentDay.format('YYYY-MM-DD');
            const groupedEvents = {};
            if (events) {
              (events[key] || []).forEach(e => {
                if (!groupedEvents[e.type]) groupedEvents[e.type] = [];
                groupedEvents[e.type].push(e);
              });
            }
            const selected = selectedDate && selectedDate.toString() === day.toString();
            const disabled = this.props.disabled || (momentDay.isBefore(today) && !allowPast);
            const disable = this.props.disabled || momentDay.isBefore(today)
            return <Col key={index}
                        style={disable ? {height: '120px', border: "solid 1px", borderColor:"#dee2e6", paddingLeft:"6px", paddingRight:"6px", backgroundColor:"#f6f6f6"}
                        : selected ? {height: '120px', border: "solid 1px", borderColor:"#3a3c42", paddingLeft:"6px", paddingRight:"6px"} :
                            {height: '120px', border: "solid 1px", borderColor:"#dee2e6", paddingLeft:"6px", paddingRight:"6px"}}
                        onClick={!disable ? this.selectDate.bind(this, day, disabled): undefined}>
              <div className="text-right mb-2" style={{lineHeight: '1em', marginTop:"3px"}}>
                <span className="date-number"><Badge pill color="danger" style={disable ? {backgroundColor:"#f6f6f6", color:"#383e4b"} : !momentDay.isSame(today)?{backgroundColor:"white", color:"#383e4b"}:{}}>{day.getDate()}</Badge></span>
              </div>
              <ul className="list-unstyled text-info mb-0" style={{fontSize: '11px', fontWeight: 'bold'}}>
                {Object.keys(groupedEvents).map((type, i) => {
                  return <EventGroup key={i}
                                     popover={popover}
                                     selectedEvent={selectedEvent}
                                     onSelectEvent={onSelectEvent}
                                     onSelectEventGroup={onSelectEventGroup}
                                     id={`d${key}-${i}`}
                                     display={display[type]()}
                                     events={groupedEvents[type]}/>;
                })}
              </ul>
            </Col>;
          })}</Row>;
        })}
        </Container>
      </Card>
    </div>;
  }
}

export default connect(({holidays, collection_date}) => {
  return {holidays, collection_date};
})(Calendar);