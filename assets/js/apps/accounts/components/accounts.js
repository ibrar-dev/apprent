import React from 'react';
import {Input} from 'reactstrap';
import Pagination from '../../../components/pagination';
import Account from './account';
import UploadCSV from './uploadCSV';
import actions from '../actions';

const headers = [
  {label: '', min: true},
  {label: 'Number', sort: 'num'},
  {label: 'Description', sort: 'charge_code'},
  {label: 'Account Name', sort: 'name'},
  {label: '', min: true},
  {label: '', min: true},
  {label: '', min: true},
  {label: '', min: true}
];

class Accounts extends React.Component {
  state = {};

  changeFilter({target: {value}}) {
    this.setState({accountFilter: value});
  }

  _filters() {
    const {accountFilter} = this.state;
    return <Input value={accountFilter || ''} onChange={this.changeFilter.bind(this)}/>
  }

  toggleUtilities() {
    this.setState({...this.state, utilities: !this.state.utilities});
  }

  render() {
    const {accounts, type} = this.props;
    const {accountFilter} = this.state;
    const titleBar = <div>
      <button onClick={actions.newAccount.bind(null, type)} className="btn btn-success mt-0 mr-3">
        New
      </button>
      <button onClick={this.toggleUtilities.bind(this)} className="btn btn-info mt-0">
        Import Utilities
      </button>
    </div>;
    const filter = new RegExp(accountFilter, 'i');
    return <React.Fragment>
      <Pagination
        title={titleBar}
        collection={accounts.filter(a => filter.test(a.name))}
        component={Account}
        headers={headers}
        filters={this._filters()}
        field="account"
        className="h-100 border-left-0 rounded-0"
      />
      {this.state.utilities && <UploadCSV toggle={this.toggleUtilities.bind(this)}/>}
    </React.Fragment>;
  }
}

export default Accounts;