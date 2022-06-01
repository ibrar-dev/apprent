import React from 'react';
import {DropdownItem, DropdownMenu, DropdownToggle, InputGroup, InputGroupButtonDropdown, Input} from 'reactstrap';
import moment from "moment";
import isInclusivelyBeforeDay from "react-dates/lib/utils/isInclusivelyBeforeDay";
import {connect} from 'react-redux';
import Pagination from '../../../components/pagination';
import Application from "./applicationRow";
import LeaseCreation from './lease';
import {capitalize} from "../../../utils";
import PropertySelect from "../../../components/propertySelect";
import DateRangePicker from "../../../components/dateRangePicker";
import actions from "../actions";

const fields = {
  property: 'Property',
  applicant: 'Applicant Name',
  status: 'Status',
  on_site: 'On Site Applicants'
};

class Applications extends React.Component {
  state = {
    filterField: 'applicant', 
    filterVal: '',
    startDate: moment().subtract(30, 'days'),
    endDate: moment()
  };
  headers = [
    {label: '', sort: null, min: true},
    {
      label: 'Property', sort: (a, b) => {
        return a.property.name > b.property.name ? 1 : -1
      }
    },
    {label: 'Unit', sort: null},
    {label: 'Applicants', sort: null},
    {label: 'Documents', sort: null},
    {label: '', sort: null, min: true},
  ];

  selectFilterField(filterField) {
    const filterVal = filterField === 'status' ? 'all' : '';
    this.setState({...this.state, filterField, filterVal});
  }

  _filters() {
    const {filterDropdownOpen, filterVal, filterField} = this.state;
    return <InputGroup>
      {filterField === 'status' ? <Input type="select" onChange={this.filterChange.bind(this)}>
        {['all', 'submitted', 'screened', 'preapproved', 'signed', 'approved', 'declined', 'conditional'].map(status => {
          return <option key={status} value={status}>{capitalize(status)}</option>;
        })}
      </Input> : <Input value={filterVal} onChange={this.filterChange.bind(this)}/>}
      <InputGroupButtonDropdown addonType="append"
                                isOpen={filterDropdownOpen}
                                toggle={this.filterDropdownOpen.bind(this)}>
        <DropdownToggle caret>
          {fields[filterField]}
        </DropdownToggle>
        <DropdownMenu>
          <DropdownItem onClick={this.selectFilterField.bind(this, 'applicant')}>Applicant</DropdownItem>
          <DropdownItem onClick={this.selectFilterField.bind(this, 'status')}>Status</DropdownItem>
          <DropdownItem onClick={this.selectFilterField.bind(this, 'on_site')}>On Site Applicants</DropdownItem>
        </DropdownMenu>
      </InputGroupButtonDropdown>
    </InputGroup>
  }

  filterDropdownOpen() {
    const {filterField, filterVal, ...currentState} = this.state;
    this.setState({...currentState, filterDropdownOpen: !this.state.filterDropdownOpen});
  }

  filterChange(e) {
    this.setState({...this.state, filterVal: e.target.value});
  }

  filtered() {
    const {applications, property} = this.props;
    const {filterVal, filterField} = this.state;
    const filter = new RegExp(filterVal, 'i');
    const toFilter = property ? applications.filter(a => a.property.id === property.id) : applications;
    switch (filterField) {
      case 'applicant':
        return toFilter.filter(app => app.persons.some(p => filter.test(p.full_name)));
      case 'status':
        return filterVal === 'all' ? toFilter : toFilter.filter(app => app.status === filterVal);
      case 'on_site':
        return toFilter.filter(app => app.device_id)
    }
  }

  datesChange(dates) {
    this.setState({...this.state, ...dates}, this.fetchApplications(dates));
  }

  fetchApplications({startDate, endDate}) {
    const {property} = this.props;
    actions.fetchApplications(property.id, startDate.format("YYYY-MM-DD"), endDate.format("YYYY-MM-DD"))
  }

  title() {
    const {properties, property} = this.props;
    const {startDate, endDate} = this.state;
    return (
      <div className="d-flex flex-row">
        <PropertySelect properties={properties} property={property} onChange={actions.setProperty}/>
        <DateRangePicker 
          startDate={startDate} 
          endDate={endDate} 
          clearField={false} 
          isOutsideRange={day => !isInclusivelyBeforeDay(day, moment())}
          onDatesChange={this.datesChange.bind(this)} />
      </div>
    )
  }

  render() {
    const {applicant, properties, property} = this.props;
    const {startDate, endDate} = this.state;

    if (properties.length == 0) {
      return <div>Loading...</div>
    }

    // console.log(startDate)

    return <React.Fragment>
      <Pagination
        title={this.title()}
        collection={this.filtered()}
        component={Application}
        headers={this.headers}
        filters={this._filters()}
        field="application"/>
      {applicant && <LeaseCreation />}
    </React.Fragment>
  }
}

export default connect(({applications, applicant, properties, property}) => {
  return {applications, applicant, properties, property};
})(Applications);
