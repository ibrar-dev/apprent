import React, {Component} from 'react';
import {connect} from 'react-redux';
import {Table, Input} from 'reactstrap';
import actions from '../actions';
import FancyCheck from '../../../components/fancyCheck';
import SelectAll from '../../../components/selectAll';

const perPage = 12;

class Charges extends Component {
  state = {
    stateResidents: this.props.residents,
    page: 0
  };

  static getDerivedStateFromProps(props, state) {
    state.stateResidents = props.residents;
    return state;
  }

  toggleResident(resident) {
    const {stateResidents} = this.state;
    let res = stateResidents.filter(r => r.id === resident.id)[0];
    res.checked = !res.checked;
    actions.setResidents(stateResidents);
    this.setState({...this.state, stateResidents: stateResidents})
  }

  changeAmount(resident, e) {
    const {stateResidents} = this.state;
    let res = stateResidents.filter(r => r.id === resident.id)[0];
    res.amount = e.target.value;
    actions.setResidents(stateResidents);
    this.setState({stateResidents});
  }

  adjustAll(checked) {
    const {stateResidents} = this.state;
    stateResidents.forEach(r => r.checked = checked);
    actions.setResidents(stateResidents);
    this.setState({stateResidents});
  }

  filteredResults() {
    const {residents} = this.props;
    const {page, filter} = this.state;
    const regex = new RegExp(filter, 'i');
    return residents.filter(r => regex.test(r.name)).slice(page * perPage, (page + 1) * perPage);
  }

  changePage(page) {
    this.setState({page});
  }

  changeFilter({target: {value}}) {
    this.setState({filter: value});
  }

  render() {
    const {stateResidents, page, filter} = this.state;
    const totalPages = Math.ceil(stateResidents.length / perPage);
    const filtered = this.filteredResults();
    const checked = stateResidents.filter(r => r.checked);
    return <div>
      <div className="d-flex justify-content-between align-items-center mt-2 mb-2 px-3">
        <span>{stateResidents.length} Residents, {checked.length} Selected</span>
        <div className="d-flex justify-content-between align-items-center">
          <Input value={filter} onChange={this.changeFilter.bind(this)} placeholder="Filter Residents"/>
          <div className="mx-4 nowrap">
            Page {page + 1} of {totalPages}
          </div>
          <ul className="pagination m-0">
            {page > 3 && <li className="page-item">
              <a className="page-link" onClick={this.changePage.bind(this, page - 4)}>
                {'<<'}
              </a>
            </li>}
            {[...Array(totalPages)].map((_, num) => {
              if (num < page - 3 || num > page + 3) return null;
              return <li className={`page-item ${page === num ? 'active' : ''}`} key={num}>
                <a className="page-link" onClick={this.changePage.bind(this, num)}>
                  {num + 1}
                </a>
              </li>;
            })}
            {page < totalPages - 3 && <li className="page-item">
              <a className="page-link" onClick={this.changePage.bind(this, page + 4)}>
                {'>>'}
              </a>
            </li>}
          </ul>
        </div>
        <span>Total: ${checked.reduce((acc, c) => parseFloat(c.amount) + acc, 0)}</span>
      </div>
      <Table striped className="m-0">
        <thead>
        <tr>
          <th className="min-width align-middle">
            <SelectAll onChange={this.adjustAll.bind(this)} list={stateResidents}/>
          </th>
          <th className="align-middle">Name</th>
          <th className="align-middle">Unit</th>
          <th className="align-middle">ID</th>
          <th className="align-middle">Amount</th>
        </tr>
        </thead>
        <tbody>
        {filtered.sort((a, b) => parseInt(a.unit) - parseInt(b.unit)).map(r => {
          return <tr key={r.id}>
            <td className="align-middle">
              <div className="d-flex align-items-center">
                <FancyCheck inline checked={r.checked} onChange={this.toggleResident.bind(this, r)}/>
              </div>
            </td>
            <td className="align-middle nowrap">
              {r.name}
            </td>
            <td className="align-middle nowrap">
              {r.unit}
            </td>
            <td className="align-middle nowrap">
              {r.id}
            </td>
            <td className="align-middle">
              <input type="number" style={{padding: '1px 5px'}} value={r.amount}
                     onChange={this.changeAmount.bind(this, r)}/>
            </td>
          </tr>
        })}
        </tbody>
      </Table>
    </div>
  }
}

export default connect(({residents}) => {
  return {residents}
})(Charges)