import React, {Component} from 'react'
import {connect} from "react-redux";
import moment from 'moment';
import {Button, Popover, PopoverBody, Col, Row, Input} from 'reactstrap';
import DatePicker from '../../../../components/datePicker';
import Select from '../../../../components/select';
import Pagination from '../../../../components/pagination';
import Check from '../../../../components/fancyCheck';
import Resident from './resident';
import GenerationModal from './generationModal';
import actions from '../../actions';

class TenantsApp extends Component {
  state = {
    filters: {
      future: false,
      past: false,
      current: true,
      amount: null,
      name: '',
      endDate: null
    }
  };

  headers = [
    {label: <Check onChange={this.selectAll.bind(this)}/>, min: true},
    {label: "Resident", sort: 'first_name'},
    {label: "Unit", sort: 'unit'},
    {label: "Balance"},
    {label: "Status"},
    {label: "Lease"},
    {label: "Preview"}
  ];

  toggleAdvanced() {
    this.setState({advanced: !this.state.advanced})
  }

  changeFilter({target: {name, value, type}}) {
    const {filters} = this.state;
    filters[name] = type === "number" ? (parseFloat(value) || null) : value;
    this.setState({filters});
  }

  changeCheckbox({target: {name}}) {
    const {filters} = this.state;
    filters[name] = !filters[name];
    this.setState({...this.state, filters: filters})
  }

  setLetter({target: {value}}) {
    this.setState({...this.state, letter: value})
  }

  checkFilters(resident) {
    const {filters: {future, past, current, amount, name, endDate}} = this.state;
    let matches = [];
    const nameTest = new RegExp(name, 'i');
    if (endDate) matches.push(moment(resident.end_date).isBefore(endDate));
    if (current) matches.push(resident.current);
    if (past) matches.push(resident.past);
    if (future) matches.push(resident.future);
    if (name.length > 0) matches.push(nameTest.test(resident.last_name) || nameTest.test(resident.first_name));
    if (amount !== 0 && resident.balance) matches.push(resident.balance >= amount);
    return matches.every(m => m === true)
  }

  residentsToDisplay() {
    const {residents} = this.props;
    return residents.filter(r => this.checkFilters(r))
  }

  toggleModal() {
    this.setState({...this.state, modal: !this.state.modal})
  }

  selectAll({target: {checked}}) {
    actions.selectAll(this.residentsToDisplay(), checked);
  }

  render() {
    const {letters} = this.props;
    const {advanced, filters, letter, modal} = this.state;
    return <>
      <Pagination collection={this.residentsToDisplay()}
                  filters={<div className="d-flex">
                    {letter && <Button onClick={this.toggleModal.bind(this)} outline color="success" className="ml-2">
                      <i className="fas fa-print"/>
                    </Button>}
                    <Button outline color="info" className="ml-2" id="advanced-filters"
                            onClick={this.toggleAdvanced.bind(this)}>
                      Advanced Filters
                    </Button>
                  </div>}
                  component={Resident}
                  headers={this.headers}
                  field="resident"
                  headerClassName="p-1"
                  title={<Select placeholder="Select Template" styles={{
                    container(provided) {
                      return {...provided, width: 350};
                    }
                  }} options={letters.map(l => {
                    return {label: l.name, value: l.id}
                  })} onChange={this.setLetter.bind(this)} value={letter}/>}
                  additionalProps={{letter}}
      />
      <Popover placement="left" isOpen={advanced} target="advanced-filters" toggle={this.toggleAdvanced.bind(this)}>
        <PopoverBody>
          <Row className="mt-1">
            <Col>
              <Row>
                <Col>
                  <div className="d-flex justify-content-between">
                    <div className="labeled-box">
                      <Input type="number" name="amount" value={filters.amount || ''}
                             onChange={this.changeFilter.bind(this)}/>
                      <div className="labeled-box-label">Min Balance Amount</div>
                    </div>
                    <div className="labeled-box ml-1">
                      <Input type="text" name="name" value={filters.name || ''}
                             onChange={this.changeFilter.bind(this)}/>
                      <div className="labeled-box-label">Resident Name</div>
                    </div>
                  </div>
                </Col>
              </Row>
              <Row className="mt-2">
                <Col>
                  <div className="labeled-box">
                    <DatePicker clearable value={filters.endDate} name="endDate"
                                onChange={this.changeFilter.bind(this)}/>
                    <div className="labeled-box-label">Leases Ending By</div>
                  </div>
                </Col>
              </Row>
              <Row>
                <Col>
                  <table className="table table-borderless">
                    <tbody>
                    <tr>
                      <td>Current</td>
                      <td><Input type="checkbox" name="current" checked={filters.current}
                                 onChange={this.changeCheckbox.bind(this)}/></td>
                    </tr>
                    <tr>
                      <td>Past</td>
                      <td><Input type="checkbox" name="past" checked={filters.past}
                                 onChange={this.changeCheckbox.bind(this)}/></td>
                    </tr>
                    <tr>
                      <td>Future</td>
                      <td>
                        <Input type="checkbox" name="future" checked={filters.future}
                               onChange={this.changeCheckbox.bind(this)}/>
                      </td>
                    </tr>
                    </tbody>
                  </table>
                </Col>
              </Row>
            </Col>
          </Row>
        </PopoverBody>
      </Popover>
      {modal && <GenerationModal letter={letter} toggle={this.toggleModal.bind(this)}/>}
    </>;
  }
}

export default connect(({residents, letters}) => {
  return {residents, letters}
})(TenantsApp)