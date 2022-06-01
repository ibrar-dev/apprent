import React from 'react';
import {Button} from 'reactstrap';

class Event extends React.Component {
  selectEvent() {
    const {event, onSelectEvent} = this.props;
    onSelectEvent(event);
  }
  render() {
    const {selected, display} = this.props;
    return <Button color={selected ? 'success' : 'info'}
                   className="event-btn btn-block"
                   onClick={this.selectEvent.bind(this)}>
      {display}
    </Button>
  }
}

export default Event;