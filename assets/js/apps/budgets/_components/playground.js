import React, {Component, Fragment} from 'react';
import {Row, Col, Table, Input} from 'reactstrap';
import Pagination from '../../../components/pagination';
import FancyCheck from '../../../components/fancyCheck';
import Select from '../../../components/select';
import {connect} from 'react-redux';
import actions from '../actions';

const headers = [
  {label: 'Name'},
  {label: 'Charge Code'},
  {label: 'Number', min: true},
  {label: 'Credit', min: true},
  {label: 'Balance', min: true},
  {label: 'Payable', min: true},
  {label: 'Cash', min: true},
]

class Account extends Component {
  state = {
    edit: false,
    account: this.props.account
  }

  change({target: {name, value}}) {
    const {account} = this.state;
    account[name] = value;
    this.setState({...this.state, account})
  }

  toggleEdit() {
    this.setState({...this.state, edit: !this.state.edit})
  }

  changeCheck({target: {name}}) {
    const {account} = this.state;
    const curValue = account[name];
    account[name] = !curValue;
    this.setState({...this.state, account})
  }

  saveAccount() {
    const {account} = this.state;
    this.setState({...this.state, edit: false});
    actions.updateAccount(account);
  }

  render() {
    const {searchedFor, extraSpans} = this.props;
    const {account, edit} = this.state;
    return <tr className={searchedFor ? 'table-info' : ''} onClick={this.toggleEdit.bind(this)}>
      <td>
        {!edit && <span>{extraSpans}{account.name}</span>}
        {edit && <div className="labeled-box" onClick={e => e.stopPropagation()}>
          <Input name="name" value={account.name} onChange={this.change.bind(this)}/>
          <div className="labeled-box-label">Name</div>
        </div>}
      </td>
      <td>
        {!edit && account.charge_code}
        {edit && <div className="labeled-box" onClick={e => e.stopPropagation()}>
          <Input name="charge_code" value={account.charge_code} onChange={this.change.bind(this)}/>
          <div className="labeled-box-label">Charge Code</div>
        </div>}
      </td>
      <td>
        {!edit && account.num}
        {edit && <div className="labeled-box" onClick={e => e.stopPropagation()}>
          <Input name="num" value={account.num} onChange={this.change.bind(this)}/>
          <div className="labeled-box-label">Number</div>
        </div>}
      </td>
      <td>
        {!edit &&
        <i className={`fas fa-${account.is_credit ? 'check-square text-success' : 'window-close text-danger'}`}/>}
        {edit && <FancyCheck inline
                             name="is_credit"
                             checked={account.is_credit}
                             value={account.is_credit}
                             onChange={this.changeCheck.bind(this)}/>}
      </td>
      <td>
        {!edit &&
        <i className={`fas fa-${account.is_balance ? 'check-square text-success' : 'window-close text-danger'}`}/>}
        {edit && <FancyCheck inline
                             name="is_balance"
                             checked={account.is_balance}
                             value={account.is_balance}
                             onChange={this.changeCheck.bind(this)}/>}
      </td>
      <td>
        {!edit &&
        <i className={`fas fa-${account.is_payable ? 'check-square text-success' : 'window-close text-danger'}`}/>}
        {edit && <FancyCheck inline
                             name="is_payable"
                             checked={account.is_payable}
                             value={account.is_payable}
                             onChange={this.changeCheck.bind(this)}/>}
      </td>
      <td>
        {!edit &&
        <i className={`fas fa-${account.is_cash ? 'check-square text-success' : 'window-close text-danger'}`}/>}
        {edit && <FancyCheck inline
                             name="is_cash"
                             checked={account.is_cash}
                             value={account.is_cash}
                             onChange={this.changeCheck.bind(this)}/>}
      </td>
      {edit && <td className="d-flex flex-column" onClick={e => e.stopPropagation()}>
        <i onClick={this.saveAccount.bind(this)} className="fas fa-save text-success cursor-pointer"/>
      </td>}
    </tr>
  }
}

class Category extends Component {
  state = {
    edit: false,
    category: this.props.category
  }

  extraSpans() {
    const {category} = this.props;
    let spans = new Array(category.depth + 1).fill().map((_, i) => {
      return <span key={i} className={"ml-2"}>{"  "}</span>
    })
    return spans
  }

  toggleEdit() {
    this.setState({...this.state, edit: !this.state.edit})
  }

  change({target: {name, value}}) {
    const {category} = this.state;
    category[name] = value;
    this.setState({...this.state, category})
  }

  updateCategory() {
    const {category} = this.state;
    this.setState({...this.state, edit: false});
    actions.updateCategory(category);
  }

  render() {
    const {filter, categories} = this.props;
    const {edit, category} = this.state;
    const {accounts} = category;
    const regex = new RegExp(filter, 'i');
    let spans = this.extraSpans();
    return <Fragment>
      <tr onClick={this.toggleEdit.bind(this)}>
        <th colSpan={2}>
          {!edit && <span>{spans}{category.name}{" "}<span className="badge badge-pill badge-light">Category</span></span>}
          {edit && <Fragment>
            <div className="labeled-box" onClick={e => e.stopPropagation()}>
              <Input name="name" value={category.name} onChange={this.change.bind(this)}/>
              <div className="labeled-box-label">Name</div>
            </div>
            <div className="labeled-box mt-2" onClick={e => e.stopPropagation()}>
              <Select value={category.parent_id}
                      name="parent_id"
                      onChange={this.change.bind(this)}
                      options={categories.filter(c => c.id !== category.id).map(c => {
                        return {label: c.name, value: c.id}
                      })}
                      placeholder="Parent Category" />
              <div className="labeled-box-label">Change Parent</div>
            </div>
          </Fragment>}
        </th>
        <td colSpan={edit ? 4 : 5}>
          {!edit && <span><b>{category.min}</b> - {category.max}</span>}
          {edit && <Fragment>
            <div className="labeled-box" onClick={e => e.stopPropagation()}>
              <Input name="min" value={category.min} onChange={this.change.bind(this)}/>
              <div className="labeled-box-label">Starting Account</div>
            </div>
            <div className="labeled-box mt-2" onClick={e => e.stopPropagation()}>
              <Input name="max" value={category.max} onChange={this.change.bind(this)}/>
              <div className="labeled-box-label">Ending Account</div>
            </div>
          </Fragment>}
        </td>
        {edit && <td onClick={e => e.stopPropagation()}>
          <i onClick={this.updateCategory.bind(this)} className="fas fa-save text-success cursor-pointer" />
        </td>}
      </tr>
      {accounts.length > 0 && <Fragment>
        {accounts.map(a => {
          const searchedFor = filter.length > 0 ? a.name.match(regex) : false;
          return <Account account={a} searchedFor={searchedFor} key={a.id} extraSpans={spans} />
        })}
        <tr>
          <th colSpan={2}>{spans}{" "}End {category.name}</th>
          <td colSpan={5}>{category.min} - <b>{category.max}</b></td>
        </tr>
      </Fragment>}
    </Fragment>
  }
}

class Playground extends Component {
  state = {filterVal: ''}

  constructor(props) {
    super(props);
    actions.fetchPlayground();
  }

  filters() {
    const {filterVal} = this.state;
    return <Input value={filterVal} onChange={this.changeFilter.bind(this)} style={{width: "100%"}}/>
  }

  changeFilter({target: {value}}) {
    this.setState({...this.state, filterVal: value});
  }

  matchAccounts(accounts, regex) {
    if (!accounts || !accounts.length) return false;
    let matches = accounts.filter(a => {
      return (a.name.match(regex))
    });
    return matches.length !== 0
  }

  filtered() {
    const {playground} = this.props;
    const {filterVal} = this.state;
    const regex = new RegExp(filterVal, 'i');
    return playground.filter(a => {
      return (a.name.match(regex) || this.matchAccounts(a.accounts, regex))
    })
  }

  extractCategories(list) {
    let new_list =  list.map(c => {
      return {id: c.id, name: c.name}
    })
    new_list.push({id: null, name: "Make Root"});
    return new_list;
  }

  render() {
    const {playground} = this.props;
    const {filterVal} = this.state;
    return <Row className="mt-1">
      <Col>
        <Pagination headers={headers}
                    filters={this.filters()}
                    field="category"
                    additionalProps={{filter: filterVal, categories: this.extractCategories(playground)}}
                    collection={this.filtered()}
                    component={Category}/>
      </Col>
    </Row>
  }

}

export default connect(({playground}) => {
  return {playground}
})(Playground);