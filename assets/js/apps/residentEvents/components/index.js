import React, {Component, Fragment} from 'react';
import {connect} from "react-redux";
import {Input} from 'reactstrap';
import moment from "moment";
import actions from '../actions';
import ResidentEvent from './event';
import ShowEvent from './show';
import NewEvent from './newEvent';
import Pagination from '../../../components/pagination';
import PropertySelect from '../../../components/propertySelect';

const headers = [
  {label: '', min: true},
  {label: '', min: true},
  {label: '', min: true},
  {label: "Name", sort: 'name'},
  {label: "Date", sort: 'date'},
  {label: "Start Time", sort: 'start_time'},
  {label: "Location", sort: 'location'},
  {label: "Info", sort: 'info'},
  {label: "Image", sort: null, min: true}
];

class EventsApp extends Component {
  state = {};

  newEvent() {
    const {event} = this.state;
    event ? this.setState({event: false}) : this.setState({newEvent: !this.state.newEvent});
  }

  eventsToDisplay() {
    const {all} = this.state;
    const {events} = this.props;
    if (all) return events;
    if (!all) return events.filter(e => moment(e.date).isAfter(moment().subtract(1, 'days')));
  }

  changeFilter(e) {
    this.setState({...this.state, filterVal: e.target.value});
  }

  _filters() {
    const {filterVal} = this.state;
    return <Input value={filterVal} onChange={this.changeFilter.bind(this)}/>
  }

  toggleAll() {
    this.setState({...this.state, all: !this.state.all})
  }

  setEditEvent(event) {
    this.setState({event: {...event, date: moment(event.date)}});
  }

  render() {
    const {property, showEvent, properties} = this.props;

    if (properties.length == 0) {
      return <div>Loading...</div>
    }

    const {newEvent, all, filterVal, event} = this.state;
    const filter = new RegExp(filterVal, 'i');
    return <Fragment>
      {(newEvent || event) && <NewEvent toggle={this.newEvent.bind(this)} event={event} property={property}/>}
      {showEvent && <ShowEvent/>}
      {!showEvent && <Pagination component={ResidentEvent}
                                 collection={this.eventsToDisplay().filter(e => filter.test(e.name))}
                                 title={<div className="d-flex align-items-center nowrap">
                                   <PropertySelect property={property} properties={properties}
                                                   onChange={actions.viewProperty}/>
                                   {all ? 'All' : 'Upcoming'} Resident Events</div>}
                                 headers={headers}
                                 filters={this._filters()}
                                 additionalProps={{setEdit: this.setEditEvent.bind(this)}}
                                 field="resident_event"
                                 menu={[
                                   {title: `${all ? 'View Upcoming' : 'View All'}`, onClick: this.toggleAll.bind(this)},
                                   {title: `New Event`, onClick: this.newEvent.bind(this)},
                                 ]}
                                 className="h-100 border-left-0 rounded-0"/>}
    </Fragment>
  }
}

export default connect(({property, properties, events, showEvent}) => {
  return {property: property || {}, events, showEvent, properties}
})(EventsApp)
