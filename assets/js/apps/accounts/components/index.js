import React, {Component} from 'react';
import {Input} from 'reactstrap';
import Pagination from '../../../components/pagination';
import NewCategory from './newCategory';
import NewAccount from './newAccount';
import Entry from './entry';
import {connect} from 'react-redux';

const headers = [
  {label: '', min: true},
  {label: 'Number', min: true},
  {label: 'Name', min: true},
  {label: 'External ID', min: true},
  {label: 'Description'},
  {label: 'Total Only', min: true},
  {label: 'In Approvals', min: true},
  {label: 'Credit', min: true},
  {label: 'Balance', min: true},
  {label: 'Payable', min: true},
  {label: 'Cash', min: true},
];

class AccountsApp extends Component {
  state = {filterVal: ''};

  filters() {
    const {filterVal} = this.state;
    return <Input value={filterVal} onChange={this.changeFilter.bind(this)} style={{width: "100%"}}/>
  }

  changeFilter({target: {value}}) {
    this.setState({...this.state, filterVal: value});
  }

  filtered() {
    const {categories} = this.props;
    const {filterVal} = this.state;
    const regex = new RegExp(filterVal, 'i');
    return categories.filter(a => {
      return (a.name.match(regex) || a.num.toString().match(regex) || this.filterExternalID(a, regex))
    })
  }

  filterExternalID(account, regex) {
    if (account.external_id) {
      return account.external_id.match(regex);
    } else {
      return false
    }
  }

  toggleNew(parent_id) {
    this.setState({...this.state, newCat: !this.state.newCat, parent_id: parent_id})
  }

  toggleNewAccount() {
    this.setState({...this.state, newAccount: !this.state.newAccount})
  }

  render() {
    const {categories} = this.props;
    const categoryHeaders = categories.filter(c => c.type === 'category');
    const {newCat, parent_id, newAccount} = this.state;
    return <div className="mt-1">
        <Pagination headers={headers}
                    filters={this.filters()}
                    title="Accounts"
                    field="entry"
                    additionalProps={{categories: categoryHeaders}}
                    keyFunc={entry => `${entry.type}-${entry.id}-${entry.num}-${entry.name}`}
                    tableClasses="sticky-header table-sm"
                    menu={[
                      {title: 'New Category', onClick: this.toggleNew.bind(this)},
                      {title: 'Add Account', onClick: this.toggleNewAccount.bind(this)}
                    ]}
                    collection={this.filtered()}
                    component={Entry}/>
      {newCat && <NewCategory toggle={this.toggleNew.bind(this)} categories={categories} props_parent_id={parent_id} />}
      {newAccount && <NewAccount toggle={this.toggleNewAccount.bind(this)} />}
    </div>;
  }
}

export default connect(({categories}) => {
  return {categories}
})(AccountsApp);
