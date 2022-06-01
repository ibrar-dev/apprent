import React, {Component} from 'react';
import moment from 'moment';
import canEdit from '../../../components/canEdit';
import icons from '../../../components/flatIcons';
import actions from '../actions';

class Event extends Component {
  state = {};

  showEvent() {
    const {resident_event: {id}} = this.props;
    actions.showEvent(id)
  }

  render() {
    const {resident_event, setEdit} = this.props;
    return <tr>
      <td>{canEdit(["Super Admin", "Regional", "Admin"]) && <i className="fas fa-times text-danger" onClick={() => actions.deleteEvent(resident_event.id, resident_event.property)} />}</td>
      <td>{(canEdit(["Super Admin", "Regional"]) || moment().format("YYYY-MM-DD") === resident_event.date) && <i onClick={this.showEvent.bind(this)} className='fas fa-eye' />}</td>
      <td>{canEdit(["Super Admin", "Regional", "Admin"]) && <i onClick={setEdit.bind(this, resident_event)} className='fas fa-edit' style={{cursor: 'pointer'}} />}</td>
      <td>{resident_event.name}</td>
      <td>{resident_event.date}</td>
      <td>{moment.utc(resident_event.date).startOf('day').add(resident_event.start_time, 'minutes').format("h:mmA")}</td>
      <td>{resident_event.location}</td>
      <td>{resident_event.info}</td>
      <td><img src={resident_event.image ? resident_event.image : icons.cancel} className='img-fluid' style={{maxWidth: 25, maxHeight: 25}} alt=""/></td>
    </tr>
  }
}

export default Event;