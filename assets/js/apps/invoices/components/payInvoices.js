import React from 'react';
import {Modal, ModalHeader, ModalBody, ModalFooter, Button} from 'reactstrap';
import Select from "../../../components/select";

class PayInvoices extends React.Component {
  state = {};

  change({target: {name, value}}) {
    this.setState({[name]: value})
  }

  render() {
    const {toggle, bankAccounts, additionalFilters, togglePayMode} = this.props;
    const {bankId} = this.state;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>
        Pay Invoices
      </ModalHeader>
      <ModalBody>
        <Select
          options={bankAccounts.filter(b => !additionalFilters.bank_id || additionalFilters.bank_id === b.id).map(b => ({
            label: b.name,
            value: b.id
          }))}
          onChange={this.change.bind(this)}
          name="bankId"
          value={bankId || ''}
          placeholder="Bank Account"/>
      </ModalBody>
      <ModalFooter>
        <Button color="danger" onClick={toggle}>Cancel</Button>
        <Button disabled={!bankId} color="success" onClick={() => togglePayMode(bankId)}>Create Checks</Button>
      </ModalFooter>
    </Modal>;
  }
}

export default PayInvoices;