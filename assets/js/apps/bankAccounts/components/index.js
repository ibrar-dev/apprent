import React from 'react';
import {connect} from 'react-redux';
import Pagination from '../../../components/pagination';
import Account from './account';
import AccountModal from './accountModal';

const headers = [
  {label: '', min: true},
  {label: 'Name', sort: 'name'},
  {label: 'Bank', sort: 'bank_name'},
  {label: 'Properties'},
  {label: 'Cash Account'},
  {label: '', min: true}
];

class Accounts extends React.Component {
  state = {};

  newModal() {
    this.setState({...this.state, newState: !this.state.newState});
  }

  _filters() {

  }

  render() {
    const {bankAccounts} = this.props;
    const {newState} = this.state;
    const titleBar = <div style={{minHeight: 35}}>
      <button onClick={this.newModal.bind(this)} className="btn btn-success mt-0">
        New Account
      </button>
    </div>;
    return <React.Fragment>
      <Pagination title={titleBar}
                  collection={bankAccounts}
                  component={Account}
                  headers={headers}
                  filters={this._filters()}
                  field="account"/>
      {newState && <AccountModal account={{address: {}}} toggle={this.newModal.bind(this)}/>}
    </React.Fragment>;
  }
}

export default connect(({bankAccounts}) => {
  return {bankAccounts};
})(Accounts);