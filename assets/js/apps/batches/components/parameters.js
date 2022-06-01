import React, {Component} from 'react';
import {connect} from 'react-redux';
import moment from 'moment';
import {Input, Button} from 'reactstrap';
import {ValidatedSelect} from "../../../components/validationFields";
import DatePicker from '../../../components/datePicker';
import MonthPicker from '../../../components/datePicker/monthPicker';
import actions from '../actions';

class Parameters extends Component {
  state = {
    property: {},
    account: {},
    postDate: moment(),
    billDate: moment(),
    note: '',
    status: 'current',
    postMonth: ''
  };

  change(type, e) {
    this.setState({...this.state, [type]: e.target.value})
  }

  changePostDate({target: {name, value}}){
    const firstOfMonth = moment(value).startOf("month");
    this.setState({...this.state, [name]: firstOfMonth});
  }

  saveCharges() {
    const {account, billDate, postDate, note} = this.state;
    const {residents} = this.props;
    const batch = {
      account_id: account.id,
      postDate: billDate,
      note: note,
      postMonth: moment(postDate).startOf('month').format("YYYY-MM-DD"),
      residents: residents.filter(r => r.checked)
    };
    actions.saveCharges(batch)
  }

  render() {
    const {accounts} = this.props;
    const {account, postDate, note, billDate} = this.state;
    return <div className="d-flex justify-content-between align-items-center">
      <div className="d-flex align-items-center w-25">
        <label className="m-0 mr-2">Account</label>
        <ValidatedSelect context={this}
                         validation={({id}) => !!id}
                         feedback="Please select a property"
                         placeholder='Select Charge Account'
                         value={account}
                         maxMenuHeight={210}
                         onChange={this.change.bind(this, 'account')}
                         menuPlacement="top"
                         options={accounts.map(p => {
                           return {value: p, label: p.name}
                         })}/>
      </div>
      <div className="d-flex align-items-center w-25 pl-4">
        <label className="m-0 mr-2">Bill Date</label>
        <DatePicker onChange={this.change.bind(this, 'billDate')}
                    options={{openDirection: 'up'}}
                    value={billDate} name="billDate"/>
      </div>
      <div className="d-flex align-items-center w-25 pl-4">
        <label className="m-0 mr-2">Post Month</label>
        <MonthPicker onChange={this.changePostDate.bind(this)}
                    options={{openDirection: 'up'}}
                    month={moment(postDate)}
                    value={postDate} name="postDate"/>
      </div>
      <div className="d-flex align-items-center w-25 pl-4">
        <label className="m-0 mr-2">Note</label>
        <Input value={note} onChange={this.change.bind(this, 'note')} placeholder="Note Optional"/>
      </div>
      <div className="w-25 pl-4">
        <Button onClick={this.saveCharges.bind(this)} block color="success">Post Charges</Button>
      </div>
    </div>
  }
}

export default connect(({properties, accounts, residents}) => {
  return {properties, accounts, residents}
})((Parameters))