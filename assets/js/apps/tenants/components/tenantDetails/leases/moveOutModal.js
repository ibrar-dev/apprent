import React from 'react';
import {Modal, ModalHeader, ModalBody, ModalFooter, Button, Input} from 'reactstrap';
import moment from "moment";
import CheckDetails from './checkDetails';
import DatePicker from '../../../../../components/datePicker';
import Check from '../../../../../components/fancyCheck';
import Select from '../../../../../components/select';
import {toCurr} from '../../../../../utils';
import actions from "../../../actions";
import ProrateCharges from './prorateCharges.js'

const afterToday = (date) => date.isAfter(moment().endOf('day'));

class MoveOutModal extends React.Component {
  state = {
    actual_move_out: this.props.lease.actual_move_out || this.props.lease.move_out_date,
    bankAccounts: [],
    charges: [],
    bankAccount: {id: 0},
    check: {date: moment().format('YYYY-MM-DD'), tenant_id: this.props.tenant.id, lease_id: this.props.lease.id}
  };

  componentDidMount() {
    actions.fetchBankAccounts(this.props.lease.property.id).then(r => {
      this.setState({bankAccounts: r.data});
      if (r.data.length === 1) this.selectBankAccount({target: {value: r.data[0].id}});
    })
  }

  leaseBalance() {
    const {transactions} = this.props;
    return transactions.reduce((sum, t) => {
      if (t.status !== 'voided' && (!t.isPayment || t.status === 'cleared' || t.nsf_id)) {
        return sum + (t.amount * (t.isPayment ? -1 : 1));
      } else {
        return sum;
      }
    }, 0);
  }

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  changeCheck({target: {name, value}}) {
    this.setState({check: {...this.state.check, [name]: value}});
  }

  closeMode({target: {checked}}) {
    const {lease: {deposit_amount}} = this.props;
    this.setState({
      closeMode: checked,
      check: {...this.state.check, amount: (this.leaseBalance() * -1) + deposit_amount}
    });
  }

  save() {
    const {toggle, lease} = this.props;
    const {closeMode, charges} = this.state;
    let promise;
    if (closeMode) {
      promise = actions.lockLease(lease.id, {...this.state}).then(toggle);
    } else {
      promise = actions.updateLease({id: this.props.lease.id, actual_move_out: this.state.actual_move_out}).then(toggle);
    }
    if (charges.length){
      promise.then(() => actions.createCharges({batch_charges: charges, lease_id: this.props.lease.id, date: new Date}))
    }
  }

  selectBankAccount({target: {value}}) {
    const bankAccount = this.state.bankAccounts.find(b => b.id === value);
    this.setState({
      bankAccount,
      check: {...this.state.check, bank_account_id: bankAccount.id, number: bankAccount.max_number + 1}
    });
  }

  render() {
    const {toggle, lease: {deposit_amount}, tenant, transactions} = this.props;
    const {actual_move_out, closeMode, bankAccounts, bankAccount, check, charges} = this.state;
    return <Modal isOpen={true} toggle={toggle} size="lg">
      <ModalHeader toggle={toggle}>Move Out Tenant</ModalHeader>
      <ModalBody>
        <div className="labeled-box">
          <DatePicker value={actual_move_out} name="actual_move_out" onChange={this.change.bind(this)}
                      isOutsideRange={afterToday}/>
          <div className="labeled-box-label">Actual Move Out</div>
        </div>
        {transactions && <div className="d-flex align-items-center mt-3">
          <Check onChange={this.closeMode.bind(this)} value={closeMode}/>
          <div className="ml-2">{check.amount > 0 ? 'Print check and c' : 'C'}lose lease</div>
        </div>}
        {closeMode && <div className="mb-4">
          <div>
            Ending Balance: {toCurr(this.leaseBalance() + deposit_amount)}, Deposit Amount: {toCurr(deposit_amount)}
          </div>
          <div className="labeled-box my-3">
            <Select value={bankAccount.id} onChange={this.selectBankAccount.bind(this)}
                    options={bankAccounts.map(b => {
                      return {label: b.name, value: b.id};
                    })}/>
            <div className="labeled-box-label">Bank Account</div>
          </div>
          <div className="labeled-box">
            <Input value={check.amount} onChange={this.changeCheck.bind(this)} name="amount"/>
            <div className="labeled-box-label">Amount</div>
          </div>
          {check.amount && bankAccount.id !== 0 && <CheckDetails account={bankAccount}
                                                                 check={check}
                                                                 onChange={this.changeCheck.bind(this)}
                                                                 tenant={tenant}/>}
        </div>}
        <ProrateCharges charges={charges} leaseId={this.props.lease.id} actualMoveOut={this.state.actual_move_out} change={this.change.bind(this)}/>
      </ModalBody>
      <ModalFooter>
        <Button onClick={() => this.props.toggle('SODACharges')}>
          Add Charges
        </Button>
        <Button color="success" onClick={this.save.bind(this)}>
          Move Out
        </Button>
      </ModalFooter>
    </Modal>;
  }
}

export default MoveOutModal;
