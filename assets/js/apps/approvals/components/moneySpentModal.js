import React, {Component} from 'react';
import {Modal, ModalBody, ModalHeader, Table} from 'reactstrap';
import {connect} from "react-redux";
import actions from '../actions';
import ModalTypePurchase from './approvalTypes/modalTypePurchase';

class MoneySpentModal extends Component {
  state = {
  }

  constructor(props) {
    super(props);
    const {category, property, property_id} = this.props;
    actions.getMoneySpent({category_id: category, property_id: property_id});
  }

  render() {
    const {moneySpent, category, toggle} = this.props;
    return <Modal style={{maxWidth: '80%'}} isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>
        Detailed cost for {moneySpent.name || ""} This Month
      </ModalHeader>
      <ModalBody>
        <Table size="sm">
          <thead>
            <tr>
              <th>Vendor</th>
              <th>Requestor</th>
              <th>Date</th>
              <th>Unit</th>
              <th>Number</th>
              <th>Cost</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
          {moneySpent.approvals && moneySpent.approvals.map(a => {
            return <ModalTypePurchase key={a.id} approval={a} category={category} />
          })}
          </tbody>
        </Table>
      </ModalBody>
    </Modal>
  }
}

export default connect(({moneySpent, payees}) => {
  return {moneySpent, payees}
})(MoneySpentModal)