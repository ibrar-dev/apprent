import React from 'react';
import {connect} from 'react-redux';
import {Modal, ModalHeader, ModalFooter, ModalBody, Button, Table, Input} from 'reactstrap';
import {toCurr} from "../../../../../utils";
import moment from "moment";
import actions from "../../../actions";
import canEdit from "../../../../../components/canEdit";
import Select from "../../../../../components/select";
import DatePicker from "../../../../../components/datePicker";
import snackbar from "../../../../../components/snackbar";

class Charge extends React.Component {

  render() {
    const {chargeCodes, change, charge, deleteCharge} = this.props;
    return <tr>
      <td className="align-middle min-width pr-0">
        <a onClick={deleteCharge}>
          {canEdit('Super Admin') && <i className="fas fa-times text-danger"/>}
        </a>
      </td>
      <td>
        <Select value={charge.charge_code_id}
                options={chargeCodes.map(a => ({value: a.id, label: `${a.code} - ${a.name}`}))}
                onChange={change}
                name="charge_code_id"/>
      </td>
      <td>
        <Input value={charge.amount} type="number" onChange={change} name="amount"/>
      </td>
      <td>
        <DatePicker value={charge.from_date} clearable
                    onChange={change} name="from_date" feedback="Please select a date"
                    isOutsideRange={(x) => !!charge.to_date && (moment.isMoment(charge.to_date) ? charge.to_date < x : moment(charge.to_date) < x)}/>
      </td>
      <td>
        <DatePicker value={charge.to_date} clearable
                    onChange={change} name="to_date" feedback="Please select a date"
                    isOutsideRange={(x) => !!charge.from_date && (moment.isMoment(charge.from_date) ? charge.from_date > x : moment(charge.from_date) > x)}/>
      </td>
    </tr>
  }
}

class LeaseChargesModal extends React.Component {
  state = {charges: [...this.props.charges]};

  save() {
    const {lease, toggle} = this.props;
    actions.saveLeaseCharges(lease.id, this.state.charges).then(toggle).catch(e => {
      snackbar({
        message: e.response.data.error,
        args: {type: 'error'}
      });
    });
  }

  changeCharge(index, {target: {name, value}}) {
    const {charges} = this.state;
    console.log(charges, name, value)
    charges[index] = {...charges[index], [name]: value};
    this.setState({charges: [...charges]});
  }

  addCharge() {
    const {charges} = this.state;
    charges.push({});
    this.setState({charges: [...charges]});
  }

  deleteCharge(index) {
    const {charges} = this.state;
    charges.splice(index, 1);
    this.setState({charges: [...charges]});
  }

  render() {
    const {toggle, chargeCodes} = this.props;
    const {charges} = this.state;
    const now = moment();
    return <Modal isOpen={true} toggle={toggle} size="xl">
      <ModalHeader toggle={toggle}>
        Lease Charges
      </ModalHeader>
      <ModalBody className="p-0">
        <Table>
          <thead>
          <tr>
            <th/>
            <th style={{minWidth: 240}}>Type</th>
            <th style={{width: 125}}>Amount</th>
            <th>From</th>
            <th>To</th>
          </tr>
          </thead>
          <tbody>
          {charges.map((charge, index) => <Charge key={charge.id || index} chargeCodes={chargeCodes}
                                                  deleteCharge={this.deleteCharge.bind(this, index)}
                                                  change={this.changeCharge.bind(this, index)}
                                                  charge={charge}/>)}
          <tr>
            <td colSpan={2}>
              Total:
            </td>
            <td>
              {toCurr(charges.reduce((s, c) => {
                if (!c.to_date || now.isBetween(moment(c.from_date), moment(c.to_date))) return s + parseFloat(c.amount);
                return s;
              }, 0))}
            </td>
            <td colSpan={2}/>
            <td><Button color="primary" onClick={this.addCharge.bind(this)}><i className="fas fa-plus" /></Button></td>
          </tr>
          </tbody>
        </Table>
      </ModalBody>
      <ModalFooter>
        <Button color="danger" onClick={toggle}>Cancel</Button>
        <Button color="success" onClick={this.save.bind(this)}>Save</Button>
      </ModalFooter>
    </Modal>;
  }
}

export default connect(({chargeCodes}) => ({chargeCodes}))(LeaseChargesModal);