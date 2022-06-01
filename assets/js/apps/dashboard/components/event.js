import React from 'react';
import {Card, CardHeader, CardBody} from 'reactstrap';
import {capitalize} from '../../../utils';

class Event extends React.Component {
  render() {
    const {event} = this.props;
    return <Card>
      <CardHeader>
        <h5 className="m-0">{capitalize(event.type.replace('_', ' '))}</h5>
      </CardHeader>
      <CardBody>
        <div>{event.property} Unit {event.unit.number}</div>
        <div>{event.tenant.first_name} {event.tenant.last_name}</div>
      </CardBody>
    </Card>;
  }
}

export default Event;