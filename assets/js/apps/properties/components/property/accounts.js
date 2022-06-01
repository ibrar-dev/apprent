import React from 'react';
import {connect} from 'react-redux';
import {Row, Col, Button} from 'reactstrap';
import Select from '../../../../components/select';
import Checkbox from '../../../../components/fancyCheck';
import confirmation from '../../../../components/confirmationModal';
import actions from '../../actions';

class AccountSection extends React.Component {
  state = {};

  newAccount() {
    this.setState({newAccount: true});
  }

  createRegister({target: {value}}) {
    const {property, type} = this.props;
    const params = {account_id: value, property_id: property.id, type};
    if (property.accounts.filter(c => c.type === type && c.is_default).length === 0) params.is_default = true;
    actions.saveRegister(params).then(() => {
      this.setState({newAccount: false});
    });
  }

  markDefault(account, {target: {checked}}) {
    if (checked) {
      const {property, type} = this.props;
      property.accounts.forEach(a => {
        a.is_default && a.type === type && actions.saveRegister({id: a.id, is_default: false});
      });
      actions.saveRegister({id: account.id, is_default: true, type});
    }
  }

  deleteRegister(account) {
    confirmation('Remove this account from this property?').then(() => {
      actions.deleteRegister(account);
    });
  }

  render() {
    const {property, accounts, name, type} = this.props;
    const registers = property.accounts.filter(a => a.type === type);
    const {newAccount} = this.state;
    return <Row>
      <Col sm={11}>
        <h3>{name}</h3>
        <ul className="list-group">
          {newAccount && <li className="list-group-item">
            <Select name="account_id"
                    options={accounts.map(a => {
                      return {value: a.id, label: a.name};
                    })}
                    onChange={this.createRegister.bind(this)}/>
          </li>}
          {registers.map(account => {
            return <li className="list-group-item d-flex align-items-center"
                       style={{backgroundColor: account.is_default ? '#d1e3d5' : ''}}
                       key={account.id}>
              <Checkbox checked={account.is_default} onChange={this.markDefault.bind(this, account)}/>
              <div className="ml-2">{account.name}</div>
              <div className="ml-auto">
                {account.is_default ? 'Default Account' : <a onClick={this.deleteRegister.bind(this, account)}>
                  <i className="fas fa-2x fa-times text-danger"/>
                </a>}
              </div>
            </li>;
          })}
          <li className="list-group-item text-right">
            <Button color="success" size="sm" onClick={this.newAccount.bind(this)}>
              <i className="fas fa-plus"/> Add
            </Button>
          </li>
        </ul>
      </Col>
    </Row>;
  }
}

class Accounts extends React.Component {
  render() {
    const {property, accounts} = this.props;
    return <div>
      <AccountSection name="Cash Accounts"
                      type="cash"
                      property={property}
                      accounts={accounts.filter(a => a.is_cash)}/>
      <AccountSection name="Receivable Accounts"
                      type="receivable"
                      property={property}
                      accounts={accounts}/>
      <AccountSection name="Prepaid Rent"
                      type="prepaid"
                      property={property}
                      accounts={accounts.filter(a => !(a.is_payable || a.is_cash))}/>
    </div>
  }
}

export default connect(({accounts}) => {
  return {accounts};
})(Accounts);