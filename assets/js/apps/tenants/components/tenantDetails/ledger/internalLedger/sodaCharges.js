import React from 'react';
import {connect} from 'react-redux';
import moment from 'moment';
import {Modal, ModalHeader, ModalBody, ModalFooter, Table, Button, Row, Col} from 'reactstrap';
import {
  ValidatedInput,
  ValidatedSelect,
  ValidatedDatePicker,
  validate
} from '../../../../../../components/validationFields';
import actions from '../../../../actions';

class SODACharges extends React.Component {
  state = {charges: [{id: 1}], date: moment(), lease_id: this.props.tenant.leases.reverse()[0].id};

  newCharge() {
    const {charges} = this.state;
    const maxId = charges.reduce((maxId, charge) => {
      return charge.id > maxId ? maxId : charge.id + 1
    }, 1);
    charges.push({id: maxId});
    this.setState({charges});
  }

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  changeAmount(index, {target: {value}}) {
    const {charges} = this.state;
    charges[index].amount = value;
    this.setState({charges});
  }

  toggle = () => {
    let lease = this.props.tenant.leases.find((lease) => {
      return lease.id === this.state.lease_id;
    })
    if(!lease.actual_move_out){
      this.props.toggle('moveOut')
    }
    else {
      this.props.toggle()
    }
  }

  changeDamage(index, {target: {value}}) {
    const {charges} = this.state;
    const {damages} = this.props;
    const damage = damages.find(d => d.id === value);
    charges[index].description = damage.name;
    charges[index].account_id = damage.account_id;
    charges[index].damageId = damage.id;
    charges[index].accountName = damage.account;
    this.setState({charges});
  }

  remove(index) {
    const {charges} = this.state;
    charges.splice(index, 1);
    this.setState({charges});
  }

  save() {
    validate(this).then(() => {
      const {charges, date, lease_id} = this.state;
      const params = charges.map(c => {
        return {description: c.description, account_id: c.account_id, amount: c.amount, status: 'manual'};
      });
      actions.createCharges({batch_charges: params, date: date.format('YYYY-MM-DD'), lease_id}).then(this.toggle());
    });
  }

  render() {
    const {toggle, damages, tenant: {leases}} = this.props;
    const {charges, date, lease_id} = this.state;
    return <Modal isOpen={true} toggle={toggle} size="lg">
      <ModalHeader toggle={toggle}>
        SODA Charges
      </ModalHeader>
      <ModalBody>
        <Row>
          <Col sm={4}>
            <label className="m-0 d-flex align-items-center">
              Date:
              <div className="ml-2 flex-auto">
                <ValidatedDatePicker context={this}
                                     name="date"
                                     validation={v => moment.isMoment(v)}
                                     feedback="Date is required"
                                     value={date}
                                     onChange={this.change.bind(this)}/>
              </div>
            </label>
          </Col>
          <Col sm={8}>
            <label className="m-0 w-100 d-flex align-items-center">
              Lease:
              <div className="ml-2 flex-auto">
                <ValidatedSelect context={this}
                                 validation={(v) => !!v}
                                 feedback="Must choose a lease"
                                 options={leases.map(l => {
                                   return {
                                     label: `${l.property.name} ${l.unit.number} ${l.start_date} - ${l.end_date}`,
                                     value: l.id
                                   };
                                 })}
                                 value={lease_id}
                                 onChange={this.change.bind(this)}/>
              </div>
            </label>
          </Col>
        </Row>
        <Table className="m-0">
          <thead>
          <tr>
            <th className="min-width border-top-0">
              <button className="btn btn-success rounded-circle py-1 px-2" onClick={this.newCharge.bind(this)}>
                <i className="fas fa-plus"/>
              </button>
            </th>
            <th className="align-middle border-top-0">Account</th>
            <th className="align-middle border-top-0">Charge</th>
            <th className="align-middle border-top-0" style={{width: '7em'}}>Amount</th>
          </tr>
          </thead>
          <tbody>
          {charges.map((charge, index) => {
            return <tr key={charge.id}>
              <td className="align-middle text-center">
                {/*<a onClick={this.remove.bind(this, index)}>*/}
                  {/*<i className="fas fa-times text-danger fa-2x"/>*/}
                {/*</a>*/}
              </td>
              <td className="align-middle">
                {charge.accountName}
              </td>
              <td>
                <ValidatedSelect context={this}
                                 validation={(v) => !!v}
                                 feedback="Must choose a damage category"
                                 options={damages.map(d => {
                                   return {label: d.name, value: d.id};
                                 })}
                                 value={charge.damageId}
                                 onChange={this.changeDamage.bind(this, index)}/>
              </td>
              <td>
                <ValidatedInput context={this}
                                validation={(v) => parseFloat(v)}
                                feedback="Amount is required"
                                value={charge.amount || ''}
                                onChange={this.changeAmount.bind(this, index)}/>
              </td>
            </tr>;
          })}
          </tbody>
        </Table>
      </ModalBody>
      <ModalFooter>
        <Button color="success" onClick={this.save.bind(this)}>
          Create
        </Button>
        <Button onClick={this.toggle}>Cancel</Button>
      </ModalFooter>
    </Modal>;
  }
}

export default connect(({damages, tenant}) => {
  return {damages, tenant};
})(SODACharges);