import React from 'react';
import {Button, Popover, PopoverHeader, PopoverBody, Badge} from 'reactstrap';
import Event from './event';

class EventGroup extends React.Component {
  state = {};

  toggle() {
    this.setState({...this.state, isOpen: !this.state.isOpen});
    const {onSelectEventGroup, events} = this.props;
    if (onSelectEventGroup) onSelectEventGroup(events);
  }

  render() {
    const {display, events, id, onSelectEvent, selectedEvent, popover} = this.props;
    const {isOpen} = this.state;
    return <li>
      {/*<Badge*/}
              {/*style={{fontSize:'11px', marginBottom:"2px", border:"solid 2px "}}*/}
              {/*pill*/}
              {/*id={id}*/}
              {/*className="event-btn btn-block green-back"*/}
              {/*onClick={this.toggle.bind(this)}>*/}
        {/*{display} ({events.length})*/}
      {/*</Badge>*/}
      <div className="d-flex" onClick={this.toggle.bind(this)} style={{cursor:"pointer"}}><i style={{fontSize:"7px", color:"#6fc382", marginRight:"3px",position:"relative", top:3}} className="fas fa-circle"></i><h6 style={{fontSize:"10px"}}>{display} ({events.length})</h6></div>
      {popover && <Popover isOpen={isOpen} placement="right" target={id}>
        <PopoverHeader>{display}s</PopoverHeader>
        <PopoverBody style={{maxHeight: 200, minWidth: 150, overflow: 'scroll'}}>
          {events.map((e, i) => <Event key={e.id}
                                       event={e}
                                       display={`${display} #${i + 1}`}
                                       onSelectEvent={onSelectEvent}
                                       selected={selectedEvent === e}/>)}
        </PopoverBody>
      </Popover>}
    </li>;
  }
}

export default EventGroup;