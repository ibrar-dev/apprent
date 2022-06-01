import React from 'react';
import {connect} from 'react-redux';
import {Row, Col, Table, Button, Input, InputGroup, InputGroupAddon} from 'reactstrap';
import DatePicker from '../../../../components/datePicker';
import Charges from './leaseCharges';
import Select from '../../../../components/select';
import actions from "../../actions";
import snackbar from "../../../../components/snackbar";
import moment from "moment";

const picker = (value, name, handleChange) => <DatePicker value={value} className="form-control full-width"
                                                          name={name} onChange={handleChange}/>;

function clearablePicker(value, name, handleChange, clear) {
  return <InputGroup>
    {picker(value, name, handleChange)}
    <InputGroupAddon addonType="append">
      <Button onClick={clear.bind(this, name)}
              style={{opacity: 1}}
              color="outline-gray">
        <i className="fas fa-times"/>
      </Button>
    </InputGroupAddon>
  </InputGroup>
}

class Lease extends React.Component {
  state = {charges: []};

  save() {
    actions.createTenant(this.state).then(() => {
      snackbar({message: 'Lease Created!', args: {type: 'success'}});
      this.props.toggle();
    }).catch(r => {
      snackbar({message: r.response.data.error, args: {type: 'error'}});
    });
  }

  change({target: {name, value}}) {
    if(name == "start_date") actions.fetchUnits(value)
    this.setState({...this.state, [name]: value});
  }

  clear(field) {
    this.setState({...this.state, [field]: null})
  }

  changeCharge(id, params) {
    const {charges: old} = this.state;
    const charges = old.map(c => c.id === id ? {...c, ...params} : c);
    this.setState({...this.state, charges});
  }

  deleteCharge(id) {
    const {charges: old} = this.state;
    const charges = old.filter(c => c.id !== id);
    this.setState({...this.state, charges});
  }

  addCharge() {
    const {charges} = this.state;
    const maxId = charges.reduce((max, c) => c.id > max ? c.id : max, 0);
    const first_month = moment().startOf('month');
    const from_date = moment().startOf('day').isAfter(first_month) ? first_month.add(1, "months") : first_month;
    charges.push({id: maxId + 1, from_date: from_date});
    this.setState({...this.state, charges});
  }

  render() {
    const {property_id, ...tenant} = this.state;
    const {properties, units} = this.props;
    const change = this.change.bind(this);
    return <div>
      <Row>
        <Col>
          <Table>
            <tbody>
            <tr>
              <th className="nowrap align-middle border-0">First Name</th>
              <td className="border-0">
                <Input className="mr-2" name="first_name" value={tenant.first_name || ''} onChange={change}/>
              </td>
            </tr>
            <tr>
              <th className="nowrap align-middle">Email</th>
              <td>
                <Input className="mr-2" name="email" value={tenant.email || ''} onChange={change}/>
              </td>
            </tr>
            <tr>
              <th className="nowrap align-middle">Property</th>
              <td>
                <Select name="property_id"
                        value={property_id}
                        options={properties.map(p => {
                          return {label: p.name, value: p.id};
                        })}
                        onChange={this.change.bind(this)}/>
              </td>
            </tr>
            <tr>
              <th className="nowrap align-middle">Lease Start</th>
              <td>
                {picker(tenant.start_date, 'start_date', change)}
              </td>
            </tr>
            <tr>
              <th className="nowrap align-middle">Lease End</th>
              <td>
                {picker(tenant.end_date, 'end_date', change)}
              </td>
            </tr>
            <tr>
              <th className="nowrap align-middle">Expected Move In</th>
              <td>
                {clearablePicker.call(this, tenant.expected_move_in, 'expected_move_in', change, this.clear)}
              </td>
            </tr>
            <tr>
              <th className="nowrap align-middle">Actual Move In</th>
              <td>
                {clearablePicker.call(this, tenant.actual_move_in, 'actual_move_in', change, this.clear)}
              </td>
            </tr>
            </tbody>
          </Table>
        </Col>
        <Col>
          <Table>
            <tbody>
            <tr>
              <th className="nowrap align-middle border-0">Last Name</th>
              <td className="border-0">
                <Input className="mr-2" name="last_name" value={tenant.last_name || ''} onChange={change}/>
              </td>
            </tr>
            <tr>
              <th className="nowrap align-middle">Phone</th>
              <td>
                <Input className="mr-2" name="phone" value={tenant.phone || ''} onChange={change}/>
              </td>
            </tr>
            <tr>
              <th className="nowrap align-middle">Unit</th>
              <td>
                <Select name="unit_id"
                        value={tenant.unit_id}
                        options={units.filter(u => u.property_id === property_id).map(u => {
                          return {label: u.number, value: u.id};
                        })}
                        onChange={this.change.bind(this)}/>
              </td>
            </tr>
            <tr>
              <th className="nowrap align-middle">Notice Given</th>
              <td>
                {clearablePicker.call(this, tenant.notice_date, 'notice_date', change, this.clear)}
              </td>
            </tr>
            <tr>
              <th className="nowrap align-middle">Move Out Date</th>
              <td>
                {clearablePicker.call(this, tenant.move_out_date, 'move_out_date', change, this.clear)}
              </td>
            </tr>
            <tr>
              <th className="nowrap align-middle">Deposit Amount</th>
              <td className="d-flex">
                <div>
                  <Input name="deposit_amount"
                         type="number"
                         value={tenant.deposit_amount || ''}
                         placeholder="Deposit Amount"
                         onChange={change}/>
                </div>
              </td>
            </tr>
            <tr>
              <td/>
              <td/>
            </tr>
            </tbody>
          </Table>
        </Col>
      </Row>
      <Row>
        <Col>
          <Charges charges={tenant.charges}
                   onChange={this.changeCharge.bind(this)}
                   deleteCharge={this.deleteCharge.bind(this)}
                   addCharge={this.addCharge.bind(this)}/>
        </Col>
      </Row>
      <Row>
        <Col sm={8}/>
        <Col>
          <Button color="info" className="btn-block" onClick={this.save.bind(this)}>
            Save
          </Button>
        </Col>
      </Row>
    </div>;
  }
}

export default connect(({properties, units}) => {
  return {properties, units}
})(Lease);