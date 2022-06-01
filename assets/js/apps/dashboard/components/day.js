import React from 'react';
import {Card, CardHeader, CardBody, ListGroup, ListGroupItem} from 'reactstrap';
import moment from 'moment';

const convertHours = (int) => {
  let base = Math.floor(int / 60);
  if (base > 12) base = base - 12;
  return base > 0 ? base + '' : '12';
};

const convertMins = int => `0${int % 60}`.replace(/\d(\d\d)/, '$1');

const convertTime = (time) => `${convertHours(time)}:${convertMins(time)}${time >= (12 * 60) ? 'P' : 'A'}M`;


const eventSummary = (event) => {
  switch (event.type) {
    case 'move_out':
      return <div>
        <h4 className="m-0">Move Out</h4>
        <div>{event.tenant.first_name} {event.tenant.last_name}</div>
        <div>{event.property} Unit {event.unit.number}</div>
      </div>;
    case 'move_in':
      return <div>
        <h4 className="m-0">Move In</h4>
        <div>{event.tenant.first_name} {event.tenant.last_name}</div>
        <div>{event.property} Unit {event.unit.number}</div>
      </div>;
    case 'showing':
      return <div style={{textDecoration: event.cancellation ? 'line-through' : 'none'}}>
        <h4 className="m-0">Showing</h4>
        <div>{event.property} {event.unit && event.unit.number}</div>
        <div>{event.prospect.name}</div>
        <div>{convertTime(event.time[0])} - {convertTime(event.time[1])}</div>
      </div>;
    case 'memo':
      return <div>
        <h4 className="m-0">Memo - {event.property}</h4>
        <div>{event.tenant.first_name} {event.tenant.last_name}</div>
        <div>{event.description}</div>
        <div>Recorded by {event.admin}</div>
      </div>;
    case 'resident_event':
      return <div>
        <h4 className="m-0">Event - {event.name}</h4>
        <div>Start Time - {moment.utc(event.date).startOf('day').add(event.start_time, 'm').format("h:mmA")}</div>
        <div>Recorded by {event.admin}</div>
      </div>;
    default:
      return null;
  }
};

class Day extends React.Component {
  render() {
    const {events, date} = this.props;
    return <Card>
      <CardHeader style={{backgroundColor:"#f6f6f6"}}>
        <h5 className="m-0">{moment(date).format('MM/DD/YYYY')}</h5>
      </CardHeader>
      <CardBody style={{height:"738px", overflowY:"scroll"}}>
        <ListGroup className="list-unstyled">
          {events.map(e => {
            return <ListGroupItem key={e.id}>
              {eventSummary(e)}
            </ListGroupItem>
          })}
        </ListGroup>
      </CardBody>
    </Card>;
  }
}

export default Day;