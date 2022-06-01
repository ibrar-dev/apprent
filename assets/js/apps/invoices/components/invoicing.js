import React from 'react';
import moment from 'moment';
import {connect} from 'react-redux';
import NewPayment from './newPayment';
import {Input, Button} from 'reactstrap';
import {ValidatedSelect, ValidatedInput} from '../../../components/validationFields';
import confirmation from '../../../components/confirmationModal';
import {toCurr} from '../../../utils';
import actions from '../actions';

const prepad = (number) => {
  const initial = `00000${number}`;
  return initial.substring(initial.length - 6);
};

class Invoicing extends React.Component {
  state = {};

  newPayment() {
    this.setState({...this.state, newPayment: !this.state.newPayment});
  }

  deletePayment(payment) {
    confirmation('Delete this payment?').then(() => {
      actions.deletePayment(payment);
    });
  }

  keyPress(value, e) {
    if (e.charCode === 13 || e.keyCode === 13) {
      this.props.change({target: {name: 'amount', value: `${eval(value)}`}})
    }
  }

  render() {
    const {properties, accounts, remove, change, inv, validationContext, invoice, index} = this.props;
    const {newPayment} = this.state;
    return <tr>
      <td className="align-middle text-center">
        <a onClick={remove}>
          <i className="fas fa-times fa-2x text-danger"/>
        </a>
      </td>
      <td>
        <ValidatedSelect context={validationContext}
                         feedback="Select Property"
                         tabIndex={10 + (index * 4)}
                         validation={d => !!d}
                         onChange={change} value={inv.property_id} name="property_id"
                         options={properties.map(p => {
                           return {label: p.name, value: p.id}
                         })}/>
      </td>
      <td>
        <ValidatedSelect context={validationContext}
                         tabIndex={11 + (index * 4)}
                         feedback="Select Account"
                         validation={d => !!d}
                         onChange={change} value={inv.account_id} name="account_id"
                options={accounts.filter(a => a.type !== 'cash').map(a => {
                  return {label: `${a.num} - ${a.name}`, value: a.id}
                })}/>
      </td>
      <td>
        <Input value={inv.notes || ''} name="notes" onChange={change} tabIndex={12 + (index * 4)} />
      </td>
      <td>
        <ValidatedInput context={validationContext}
                        feedback="Enter Amount"
                        tabIndex={13 + (index * 4)}
                        type="text"
                        onKeyPress={this.keyPress.bind(this, inv.amount)}
                        validation={d => !!d}
                        value={inv.amount || ''}  name="amount" onChange={change}/>
      </td>
      {<td>
        <div className="d-flex justify-content-between align-items-center">
          <ul className="list-unstyled m-0">
            {inv.payments.map(p => {
              return <li key={p.id}>
                <a onClick={this.deletePayment.bind(this, p)} className="mr-2">
                  <i className="fas fa-times text-danger"/>
                </a>
                {toCurr(p.amount)} on {moment(p.date).format('MM/DD/YYYY')} {p.check_number && `Check #${prepad(p.check_number)}`}
              </li>;
            })}
          </ul>
          <Button outline style={{color:"#3a3c42"}}
             onClick={this.newPayment.bind(this)}>Pay
          </Button>
        </div>
      </td>}
      {newPayment && <NewPayment invoicing={inv} invoice={invoice} toggle={this.newPayment.bind(this)}/>}
    </tr>
  }
}

export default connect(({properties, accounts, invoices}) => {
  return {properties, accounts, invoices};
})(Invoicing);
