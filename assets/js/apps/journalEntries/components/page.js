import React from "react";
import moment from 'moment';
import actions from '../actions';
import {withRouter} from 'react-router';
import confirmation from '../../../components/confirmationModal';
import {toCurr} from '../../../utils';

class Page extends React.Component {

  deleteEntry() {
    confirmation('Delete this journal entry?').then(() => {
      actions.deletePage(this.props.entry);
    });
  }

  render() {
    const {entry, history} = this.props;
    return <tr>
      <td className="align-middle">
        <a onClick={this.deleteEntry.bind(this)} className="d-inline-block mt-1">
          <i className="fas fa-2x fa-times text-danger"/>
        </a>
      </td>
      <td className="align-middle">{moment(entry.date).format('MM/DD/YYYY')}</td>
      <td className="align-middle">{entry.name}</td>
      <td className="align-middle">{toCurr(entry.total)}</td>
      <td className="align-middle">
        <button className="btn btn-outline-info btn-sm"
                onClick={() => history.push(`/journal_entries/${entry.id}`, {})}>
          Edit
        </button>
      </td>
    </tr>;
  }
}

export default withRouter(Page)