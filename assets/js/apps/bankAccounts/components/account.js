import React from 'react';
import {connect} from 'react-redux';
import {Button} from 'reactstrap';
import actions from '../actions';
import AccountModal from "./accountModal";

class Account extends React.Component {
  state = {account: this.props.account};

  componentWillReceiveProps(props) {
    this.setState({...this.state, account: props.account});
  }

  deleteAccount() {
    if (confirm('Delete this account?')) {
      actions.deleteBankAccount(this.props.account);
    }
  }

  toggleEditMode() {
    const {editMode} = this.state;
    this.setState({...this.state, editMode: !editMode});
  }

  render() {
    const {account, editMode} = this.state;
    return <tr>
      <td className="align-middle">
        <a onClick={this.deleteAccount.bind(this)}>
          <i className="fas fa-times fa-2x text-danger"/>
        </a>
      </td>
      <td className="align-middle">{account.name}</td>
      <td className="align-middle">{account.bank_name}</td>
      <td className="align-middle">
        {account.properties.map(p => <div key={p.id}>{p.name}</div>)}
      </td>
      <td className="align-middle">
        {account.account}
      </td>
      <td>
        <Button onClick={this.toggleEditMode.bind(this)} color="info">
          Edit
        </Button>
      </td>
      {editMode && <AccountModal toggle={this.toggleEditMode.bind(this)} account={account}/>}
    </tr>;
  }
}

export default connect(({entities, classes}) => {
  return {entities, classes};
})(Account);