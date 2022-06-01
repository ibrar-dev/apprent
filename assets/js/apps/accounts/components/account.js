import React from 'react';
import AccountModal from './accountModal';
import actions from '../actions';

class Account extends React.Component {
  state = {};

  toggleEdit() {
    this.setState({editMode: !this.state.editMode});
  }

  change({target: {name, value}}) {
    this.setState({account: {...this.state.account, [name]: value}});
  }

  render() {
    const {account} = this.props;
    console.log(account)
    const editMode = this.state.editMode || !account.id;
    return <>
      <tr>
        <td className="align-middle">
          <a onClick={this.toggleEdit.bind(this)}>
            <i className="fas fa-edit fa-lg"/>
          </a>
        </td>
        <td className="align-middle">
          {account.num}
        </td>
        <td className="align-middle nowrap">
          {account.name}
        </td>
        <td className="align-middle nowrap">
          {account.external_id}
        </td>
        <td className="align-middle">
          {account.description}{account.source_id && <span className="badge badge-danger">Source</span>}
        </td>
        <td/>
        <td/>
        <td className="align-middle text-center">
          <i className={`fas fa-${account.is_credit ? 'check-square text-success' : 'window-close text-danger'}`}/>
        </td>
        <td className="align-middle text-center">
          <i className={`fas fa-${account.is_balance ? 'check-square text-success' : 'window-close text-danger'}`}/>
        </td>
        <td className="align-middle text-center">
          <i className={`fas fa-${account.is_payable ? 'check-square text-success' : 'window-close text-danger'}`}/>
        </td>
        <td className="align-middle text-center">
          <i className={`fas fa-${account.is_cash ? 'check-square text-success' : 'window-close text-danger'}`}/>
        </td>
      </tr>
      {editMode &&
      <AccountModal categories={this.props.categories} account={account} toggle={this.toggleEdit.bind(this)}/>}
    </>
  }
}

export default Account;