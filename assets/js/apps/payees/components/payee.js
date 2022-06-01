import React from 'react';
import {withRouter} from "react-router-dom";
import confirmation from "../../../components/confirmationModal";
import actions from '../actions';

class Payee extends React.Component {

  deletePayee(e) {
    e.stopPropagation();
    confirmation('Delete this payee entirely?').then(() => {
      actions.deletePayee(this.props.payee);
    }).catch(() => {});
  }

  changeApproved(e) {
    e.stopPropagation();
    const {payee} = this.props;
    payee.approved = !payee.approved;
    actions.updatePayee(payee);
  }

  render() {
    const {payee, history} = this.props;
    return <tr className="link-row" onClick={() => history.push(`/payees/${payee.id}`)}>
      <td className="align-middle">
        <a onClick={this.deletePayee.bind(this)}>
          <i className="fas fa-times text-danger"/>
        </a>
      </td>
      <td className="align-middle">
        {payee.name}
      </td>
      <td className="align-middle nowrap">
        <a onClick={this.changeApproved.bind(this)}>
          <i className={`fas fa-${payee.approved ? 'check text-success' : 'times text-danger'}`} />
        </a>
      </td>
      <td className="align-middle nowrap">
        {payee.invoices.length} Invoices
      </td>
    </tr>;
  }
}

export default withRouter(Payee);
