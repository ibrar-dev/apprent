import React from 'react';
import {connect} from 'react-redux';
import {Input} from 'reactstrap';
import {ValidatedSelect} from "../../../components/validationFields";

class Entry extends React.Component {
  _handleKeyPress(e) {
    const type = e.target.id;
    const {parent, index} = this.props;
    parent.toggleEntryType.bind(parent, index, type)()
   }

   handleClick(e) {
    const type = e.target.id;
    const {parent, index} = this.props;
    parent.toggleEntryType.bind(parent, index, type)()
   }

  render() {
    const {parent, index, entry, canDelete, accounts, properties} = this.props;
    return <tr>
      <td className="align-middle text-center">
        {canDelete && <a onClick={parent.deleteEntry.bind(parent, index)}>
          <i className="fas fa-times fa-2x text-danger"/>
        </a>}
      </td>
      <td>
        <ValidatedSelect context={parent}
                         validation={(id) => !!id}
                         feedback="Please select a property"
                         value={entry.property_id}
                         placeholder="Select Property"
                         options={properties.map(a => {
                           return {value: a.id, label: a.name}
                         })}
                         name="property_id"
                         onChange={parent.changeEntry.bind(parent, index)}/>
      </td>
      <td>
        <ValidatedSelect context={parent}
                         validation={(id) => !!id}
                         feedback="Please select an account"
                         value={entry.account_id}
                         placeholder="Select Account"
                         options={accounts.map(a => {
                           return {value: a.id, label: `${a.num} - ${a.name}`}
                         })}
                         name="account_id"
                         onChange={parent.changeEntry.bind(parent, index)}/>
      </td>
      <td>
        <div className="d-flex"onClick={this.handleClick.bind(this)}>
          <div className="w-100">
            <Input disabled={entry.is_credit === true}
                   id='debit'
                   context={parent}
                   feedback="Please enter an amount"
                   type="number"
                   name="amount"
                   value={entry.is_credit === true ? '' : entry.amount}
                   onKeyPress={this._handleKeyPress.bind(this)}
                   onChange={parent.changeEntry.bind(parent, index)}/>
          </div>
        </div>
      </td>
      <td>
        <div className="d-flex" onClick={this.handleClick.bind(this)}>
          <div className="w-100">
            <Input disabled={entry.is_credit === false }
                   id='credit'
                   context={parent}
                   feedback="Please enter an amount"
                   type="number"
                   name="amount"
                   value={entry.is_credit === false ? '' : entry.amount}
                   onKeyPress={this._handleKeyPress.bind(this)}
                   onClick={this.handleClick.bind(this)}
                   onChange={parent.changeEntry.bind(parent, index)}/>
          </div>
        </div>
      </td>
    </tr>
  }
}

export default connect(({accounts, properties}) => {
  return {accounts, properties};
})(Entry);