import React from 'react';
import {connect} from "react-redux";
import {Button, Input} from "reactstrap";
import Select from "../../../../components/select";

class Receipt extends React.Component {

  change({target: {name, value}}) {
    const {receipt, onChange} = this.props;
    onChange(receipt, {[name]: value});
  }

  render() {
    const {accounts, removeReceipt, removable, receipt} = this.props;
    return <div className="d-flex align-items-center mb-3">
      <div style={{minWidth: 350}} className="mr-3">
        <Select name="account_id"
                placeholder="Account"
                onChange={this.change.bind(this)}
                value={receipt.account_id}
                options={accounts.map(a => {
                  return {label: a.description || a.name, value: a.id};
                })}/>
      </div>
      <div className="flex-auto mr-3">
        <Input value={receipt.amount || ''} type="number" placeholder="Amount" name="amount" onChange={this.change.bind(this)}/>
      </div>
      <div className="ml-auto">
        <Button disabled={!removable} color="danger" onClick={removeReceipt}>Remove</Button>
      </div>
    </div>
  }
}

export default connect(({accounts}) => ({accounts}))(Receipt);