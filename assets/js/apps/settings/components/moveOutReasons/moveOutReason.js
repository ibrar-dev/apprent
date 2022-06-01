import React from 'react';
import confirmation from '../../../../components/confirmationModal';
import actions from '../../actions';

class MoveOutReason extends React.Component {
  deleteMoveOutReason() {
    confirmation('Delete this move out reason?').then(() => {
      actions.deleteMoveOutReason(this.props.moveOutReason).catch(r => alert(r.response.data.error));
    });
  }

  render() {
    const {moveOutReason} = this.props;
    return <tr>
      <td>
        <a onClick={this.deleteMoveOutReason.bind(this)}>
          <i className="fas fa-times text-danger"/>
        </a>
      </td>
      <td>
        {moveOutReason.name}
      </td>
    </tr>
  }
}

export default MoveOutReason;