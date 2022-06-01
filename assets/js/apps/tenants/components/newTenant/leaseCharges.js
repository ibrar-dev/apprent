import React from 'react';
import {connect} from 'react-redux';
import {Table, Input, Button} from 'reactstrap';
import {toCurr} from '../../../../utils';
import Select from '../../../../components/select';
import DatePicker from '../../../../components/datePicker';

class LeaseCharge extends React.Component {
  deleteCharge() {
    const {charge, deleteCharge} = this.props;
    deleteCharge(charge.id);
  }

  change({target: {name, value}}) {
    const {charge, onChange} = this.props;
    onChange(charge.id, {[name]: value});
  }

  render() {
    const {chargeCodes, charge} = this.props;
    return <tr>
      <td className="align-middle min-width">
        <a onClick={this.deleteCharge.bind(this)}>
          <i className="fas fa-times text-danger"/>
        </a>
      </td>
      <td>
        <Select value={charge.charge_code_id}
                options={chargeCodes.map(a => {
                  return {value: a.id, label: a.name};
                })}
                onChange={this.change.bind(this)}
                name="account_id"/>
      </td>
      <td>
        <Input value={charge.amount || ''}
               type="number"
               onChange={this.change.bind(this)}
               name="amount"/>
      </td>
      <td>
        <DatePicker value={charge.from_date} clearable
                    onChange={this.change.bind(this)}
                    name="from_date"
        />
      </td>
      <td>
        <DatePicker value={charge.to_date}
                    onChange={this.change.bind(this)}
                    name="to_date"
        />
      </td>
    </tr>;
  }
}

const Charge = connect(({chargeCodes}) => {
  return {chargeCodes};
})(LeaseCharge);

class LeaseCharges extends React.Component {
  render() {
    const {charges, addCharge, deleteCharge, onChange} = this.props;
    return <div>
      <div className="d-flex justify-content-between align-items-center py-2">
        <h4 className="m-0">Charges</h4>
      </div>
      <Table>
        <thead>
        <tr>
          <th/>
          <th style={{minWidth: 250}}>Type</th>
          <th>Amount</th>
          <th>From</th>
          <th>To</th>
        </tr>
        </thead>
        <tbody>
        {charges.map(charge => <Charge key={charge.id}
                                       deleteCharge={deleteCharge}
                                       onChange={onChange}
                                       charge={charge}/>)}
        <tr>
          <td colSpan={2}>
            Total:
          </td>
          <td>
            {toCurr(charges.reduce((s, c) => s + parseFloat(c.amount), 0))}
          </td>
        </tr>
        </tbody>
      </Table>
      <Button onClick={addCharge} color="success">
        <i className="fas fa-plus"/> Add Charge
      </Button>
    </div>;
  }
}

export default LeaseCharges;