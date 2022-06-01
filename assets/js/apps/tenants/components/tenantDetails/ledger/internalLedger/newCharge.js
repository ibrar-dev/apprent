import React from 'react';
import {connect} from 'react-redux';
import moment from 'moment';
import {Modal, ModalHeader, ModalBody, Input, Button, Table} from 'reactstrap';
import {
  validate,
  ValidatedSelect,
  ValidatedInput,
  ValidatedDatePicker
} from '../../../../../../components/validationFields';
import MonthPicker from '../../../../../../components/datePicker/monthPicker';
import actions from '../../../../actions';

const currentMonth = moment().startOf('month').add(10, 'hours');
const chargePrototype = () => ({
  id: 0,
  account_id: undefined,
  amount: 0,
  description: '',
  date: undefined,
  post_month: currentMonth.clone()
});

class Charge extends React.Component {
  change({target: {name, value}}) {
    const {index, onChange} = this.props;
    onChange(name, value, index);
  }

  changePostDate({target: {name, value}}) {
    const {index, onChange} = this.props;
    const firstOfMonth = moment(value).startOf("month");
    onChange(name, firstOfMonth, index);
  }

  render() {
    const {charge, chargeCodes, onDelete, index, parent} = this.props;
    return <tr>
      <td className="text-center">
        {index > 0 && <a onClick={onDelete}>
          <i className="fas fa-2x fa-times text-danger"/>
        </a>}
      </td>
      <td>
        <MonthPicker onChange={this.changePostDate.bind(this)} month={moment(charge.post_month)} name="post_month"/>
      </td>
      <td>
        <ValidatedDatePicker context={parent} validation={(d) => d} name="date" value={charge.date}
                             feedback="Please select a date" onChange={this.change.bind(this)}/>
      </td>
      <td>
        <ValidatedSelect context={parent} validation={(d) => d} value={charge.charge_code_id} name="charge_code_id"
                         feedback="Please select an account"
                         onChange={this.change.bind(this)}
                         options={chargeCodes.map(ct => ({
                           value: ct.id,
                           label: `${ct.code} - ${ct.name}`
                         }))}/>
      </td>
      <td>
        <ValidatedInput context={parent} validation={(d) => d} type="number" value={charge.amount} name="amount"
                        feedback="Please enter an amount" onChange={this.change.bind(this)}/>
      </td>
      <td>
        <Input value={charge.description} name="description" onChange={this.change.bind(this)}/>
      </td>
    </tr>
  }
}

class NewCharge extends React.Component {
  state = {charges: [chargePrototype()]};

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  save() {
    const {charges} = this.state;
    const {lease} = this.props;
    const params = charges.map(charge => {
      return {...charge, bill_date: moment(charge.date).format('YYYY-MM-DD'), lease_id: lease.id}
    });
    validate(this).then(() => actions.saveCharges(params).then(this.props.toggle));
  }

  addCharge() {
    const {charges} = this.state;
    const maxId = charges.reduce((max, charge) => charge.id > max ? charge.id : max, 0);
    charges.push({...chargePrototype(), id: maxId + 1});
    this.setState({charges: [...charges]});
  }

  changeCharge(name, value, index) {
    const {charges} = this.state;
    const charge = charges[index];
    charges[index] = {...charge, [name]: value};
    this.setState({charges: [...charges]});
  }

  removeCharge(index) {
    const {charges} = this.state;
    charges.splice(index, 1);
    this.setState({charges: [...charges]});
  }

  render() {
    const {toggle, chargeCodes} = this.props;
    const {charges} = this.state;
    return <Modal isOpen={true} toggle={toggle} size="xl">
      <ModalHeader toggle={toggle}>
        New Charges
      </ModalHeader>
      <ModalBody className="p-0 pb-3">
        <Table>
          <thead>
          <tr>
            <th className="min-width">
              <a onClick={this.addCharge.bind(this)}>
                <i className="fas fa-2x fa-plus-circle text-success"/>
              </a>
            </th>
            <th className="min-width align-middle">Post Month</th>
            <th className="align-middle" style={{width: 150}}>Date</th>
            <th className="align-middle" style={{width: 300}}>Charge Code</th>
            <th className="align-middle" style={{width: 100}}>Amount</th>
            <th className="align-middle">Notes</th>
          </tr>
          </thead>
          <tbody>
          {charges.map((charge, index) => (
            <Charge key={charge.id} charge={charge} index={index} chargeCodes={chargeCodes} parent={this}
                    onDelete={this.removeCharge.bind(this, index)}
                    onChange={this.changeCharge.bind(this)}/>
          ))}
          </tbody>
        </Table>
        <div className="d-flex justify-content-center">
          <Button className="w-50" color="success" onClick={this.save.bind(this)}>
            Save
          </Button>
        </div>
      </ModalBody>
    </Modal>;
  }
}

export default connect(({tenant, chargeCodes}) => ({tenant, chargeCodes}))(NewCharge);