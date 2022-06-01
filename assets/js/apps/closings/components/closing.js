import React from 'react';
import confirmation from '../../../components/confirmationModal';
import actions from '../actions';
import moment from 'moment';

class Closing extends React.Component {
  deleteMonth(){
    confirmation('Remove this month closing?').then(() => {
      actions.deleteClosing(this.props.closing);
    });
  }
  render() {
    const {closing} = this.props;
    return <tr>
      <td>
        <a onClick={this.deleteMonth.bind(this)}>
          <i className="fas fa-times text-danger"/>
        </a>
      </td>
      <td>
        {closing.month}
      </td>
      <td>
        {moment(closing.closed_on).format('MM/DD/YYYY')}
      </td>
      <td>
        {closing.admin}
      </td>
    </tr>;
  }
}

export default Closing;