import React, {Component} from "react";
import {connect} from 'react-redux';
import moment from 'moment';
import {Row, Col, Card, CardHeader, CardBody, Popover, PopoverBody, Button} from 'reactstrap';
import PropertySelect from "../../../../components/propertySelect";
import DateRangePicker from '../../../../components/dateRangePicker';
import actions from "../../actions";
import Select from '../../../../components/select';
import Check from '../../../../components/fancyCheck';

const sortFunctions = {
  nameUp: (t1, t2) => t1.tenants[0].first_name > t2.tenants[0].first_name ? 1 : -1,
  nameDown: (t1, t2) => t1.tenants[0].first_name < t2.tenants[0].first_name ? 1 : -1
};

class ReportsApp extends Component {
  state = {
    type: "All",
    days: null,
    filterType: {insertedAt: false, updatedAt: false}
  };

  changeDates({startDate, endDate}) {
    if (moment(startDate).isAfter(moment(endDate))) endDate = moment(startDate).add(1, 'days');
    const dates = {startDate: startDate, endDate: endDate};
    actions.setDates(dates);
    actions.fetchLeases(this.props.property.id, moment(startDate).format("MM/DD/YYYY"), moment(endDate).format("MM/DD/YYYY"))
  }

  filter(){
    const {type} = this.state;
    const {leases} = this.props;
    const filteredLeases = this.filterByTypes(leases);
    switch(type){
      case "All":
        return <tbody>{this.createLeases(filteredLeases)}</tbody>;
      case "HAPRent":
        const haprent = filteredLeases.filter(l => l.charges.some(c => c.account === "HAP Rent"));
        return <tbody>{this.createLeases(haprent)}</tbody>;
      case "Leases Expiring":
        const thirtyDays = moment().add(30, 'd').format('YYYY-MM-DD');
        const sixtyDays = moment().add(60, 'd').format('YYYY-MM-DD');
        const hundredTwentyDays = moment().add(120, 'd').format('YYYY-MM-DD');
        const leases30 = filteredLeases.filter(l => l.end_date <= thirtyDays);
        const leases60 = filteredLeases.filter(l => l.end_date > thirtyDays && l.end_date <= sixtyDays);
        const leases120 = filteredLeases.filter(l => l.end_date > sixtyDays && l.end_date <= hundredTwentyDays);
        return this.leasesExpiringFilter(leases30, leases60, leases120);
      default:
        return [];
    }
  }

  setSorting(type, func){
    const newType = type === this.state.sortType ? null : type;
    this.setState({...this.state, sortType: newType, sortingFunc: func})
  }

  filterByTypes(leases){
    const {dates: {startDate, endDate}} = this.props;
    const {filterType:{insertedAt, updatedAt}, sortingFunc} = this.state;
    if(sortingFunc) leases = leases.sort(sortingFunc);
    let newLeases = [];
    const used = [];
    if(insertedAt) {
      leases.forEach(l => {
        const createdDate = moment(l.inserted_at);
        if(createdDate >= startDate && createdDate <= endDate) {
          used.push(l.id);
          newLeases.push(l);
        }
      });
    }
    if(updatedAt){
      leases.forEach(l => {
        const updatedDate = moment(l.updated_at);
        if(updatedDate >= startDate && updatedDate <= endDate && !used.includes(l.id)) {
          used.push(l);
          newLeases.push(l);
        }
      });
    }
    if(!insertedAt && !updatedAt){newLeases = leases}
    return newLeases;

  }

  findExpiringLeases(days){
    const {property} = this.props;
    const futureDay = moment().add(days, 'd').format("MM/DD/YYYY");
    const today = moment(new Date()).format("MM/DD/YYYY");
    this.setState({...this.state, days: days});
    actions.setDates({startDate: today, endDate: futureDay});
    actions.fetchLeases(property.id, today, futureDay);
  }

  createLeases(leases){
    return leases.map((l,i) => {
      const tenant = l.tenants[0];
      return <tr key={l.id} style={i % 2 === 0 ? {backgroundColor: "#f2f2f2"} : null}>
        <td><a href={`/tenants/${tenant.id}`} target="blank" className="text-dark">{tenant.first_name} {tenant.last_name}</a></td>
        <td>{l.start_date}</td>
        <td>{l.end_date}</td>
        <td>{moment(l.inserted_at).format("YYYY-MM-DD")}</td>
        <td>{moment(l.updated_at).format("YYYY-MM-DD")}</td>
        <td>{l.actual_move_in}</td>
        <td>{l.actual_move_out}</td>
        <td>{l.charges.map(c => {
          return <tr key={c.id}>
            <td><strong>{c.account}</strong>: </td>
            <td>{c.amount}</td>
          </tr>
        })}</td>
      </tr>
    })
  }

  leasesExpiringFilter(leases30, leases60, leases120){
    const today = moment().format('MM/DD/YYYY');
    const thirtyDays = moment().add(30, 'd').format('MM/DD/YYYY');
    const sixtyDays = moment().add(60, 'd').format('MM/DD/YYYY');
    const hundredTwentyDays = moment().add(120, 'd').format('MM/DD/YYYY');
    return <>
      <tbody>
        {leases30.length ? <tr><th>{today} - {thirtyDays}</th></tr> : null}
        {this.createLeases(leases30)}
      </tbody>
      <br/>
      <br/>
      <tbody>
        {leases60.length ? <tr><th>{thirtyDays} - {sixtyDays}</th></tr> : null}
        {this.createLeases(leases60)}
      </tbody>
      <br/>
      <br/>
      <tbody>
        {leases120.length ? <tr><th>{sixtyDays} - {hundredTwentyDays}</th></tr> : null}
        {this.createLeases(leases120)}
      </tbody>
    </>;
  }

  setReport({target: {value}}) {
    this.setState({type: value})
  }

  close(){
    this.setState({open: false})
  }

  open(){
    this.setState({open: true})
  }

  setFilters(value){
    const {filterType} = this.state;
    const newType = {...filterType, [value]: !filterType[value]};
    this.setState({filterType: newType});
  }

  sortLeasesUpTime(type){
    return (t1, t2) => t1[type] > t2[type] ? 1 : -1;
  }

  sortLeasesDownTime(type){
    return (t1, t2) => t1[type] < t2[type] ? 1 : -1;
  }

  render() {
    const {dates: {startDate, endDate}, property, properties} = this.props;

    if (properties.length == 0) {
      return (
        <p>Loading</p>
      )
    }

    const {type, filterType: {insertedAt, updatedAt}, open, sortType} = this.state;
    return <Card>
      <CardHeader className="d-flex justify-content-between">
        <PropertySelect property={property} properties={properties}
                        onChange={actions.viewProperty}/>
        <a className="btn btn-link cursor-pointer" href="/leases/renewals">Renewals</a>
      </CardHeader>
      <CardBody>
        <Row>
          <Col>
            <Button color="info" outline onClick={this.open.bind(this)} id={"advance-filters"}>
              Advance Filters
            </Button>
            <Popover placement="bottom" isOpen={open} target={"advance-filters"} className="popover-max"
                     toggle={this.close.bind(this)}>
              <PopoverBody style={{minWidth: 500}}>
                <Row className="mb-3">
                  <Col>
                  <Select options={["All", "HAPRent", "Leases Expiring"].map(r => {
                    return {label: r, value: r};
                  })} onChange={this.setReport.bind(this)} value={type}/>
                  </Col>
                </Row>
                <Row className="mb-1">
                  <Col className="d-flex align-items-center">
                    <Check onChange={this.setFilters.bind(this, "insertedAt")} checked={insertedAt}/>
                    <div className="ml-2">Only Created At</div>
                  </Col>
                  <Col className="d-flex align-items-center">
                    <Check onChange={this.setFilters.bind(this, "updatedAt")} checked={updatedAt}/>
                    <div className="ml-2">Only Updated At</div>
                  </Col>
                </Row>
              </PopoverBody>
            </Popover>
          </Col>
          <Col className="d-flex">
            <DateRangePicker startDate={startDate} endDate={endDate}
                              onDatesChange={this.changeDates.bind(this)}/>
          </Col>
        </Row>
        <table style={{width: "100%", marginTop: 20}}>
          <thead>
          <tr>
            <th>
              Name
              {sortType !== "name" ? <a className="ml-1" onClick={this.setSorting.bind(this, "name", sortFunctions.nameUp)}>
                    <i className="fas fa-caret-down pt-1 ml-1"/>
                  </a>
                  : <a className="ml-1" onClick={this.setSorting.bind(this, "name", sortFunctions.nameDown)}>
                    <i className="fas fa-caret-up pt-1 ml-1"/>
                  </a>}
            </th>
            <th>
              Lease Start
              {sortType !== "leaseStart" ? <a className="ml-1" onClick={this.setSorting.bind(this, "leaseStart", this.sortLeasesUpTime("start_date"))}>
                    <i className="fas fa-caret-down pt-1 ml-1"/>
                  </a>
                  : <a className="ml-1" onClick={this.setSorting.bind(this, "leaseStart", this.sortLeasesDownTime("start_date"))}>
                    <i className="fas fa-caret-up pt-1 ml-1"/>
                  </a>}
            </th>
            <th>
              Lease End
              {sortType !== "leaseEnd" ? <a className="ml-1" onClick={this.setSorting.bind(this, "leaseEnd", this.sortLeasesUpTime("end_date"))}>
                    <i className="fas fa-caret-down pt-1 ml-1"/>
                  </a>
                  : <a className="ml-1" onClick={this.setSorting.bind(this, "leaseEnd", this.sortLeasesDownTime("end_date"))}>
                    <i className="fas fa-caret-up pt-1 ml-1"/>
                  </a>}
            </th>
            <th>
              Created On
              {sortType !== "leaseCreated" ? <a className="ml-1" onClick={this.setSorting.bind(this, "leaseCreated", this.sortLeasesUpTime("inserted_at"))}>
                    <i className="fas fa-caret-down pt-1 ml-1"/>
                  </a>
                  : <a className="ml-1" onClick={this.setSorting.bind(this, "leaseCreated", this.sortLeasesDownTime("inserted_at"))}>
                    <i className="fas fa-caret-up pt-1 ml-1"/>
                  </a>}
            </th>
            <th>
              Updated On
              {sortType !== "leaseUpdated" ? <a className="ml-1" onClick={this.setSorting.bind(this, "leaseUpdated", this.sortLeasesUpTime("updated_at"))}>
                    <i className="fas fa-caret-down pt-1 ml-1"/>
                  </a>
                  : <a className="ml-1" onClick={this.setSorting.bind(this, "leaseUpdated", this.sortLeasesDownTime("updated_at"))}>
                    <i className="fas fa-caret-up pt-1 ml-1"/>
                  </a>}
            </th>
            <th>
              Moved In
              {sortType !== "movein" ? <a className="ml-1" onClick={this.setSorting.bind(this, "movein", this.sortLeasesUpTime("actual_move_in"))}>
                    <i className="fas fa-caret-down pt-1 ml-1"/>
                  </a>
                  : <a className="ml-1" onClick={this.setSorting.bind(this, "movein", this.sortLeasesDownTime("actual_move_in"))}>
                    <i className="fas fa-caret-up pt-1 ml-1"/>
                  </a>}
            </th>
            <th>
              Moved Out
              {sortType !== "moveout" ? <a className="ml-1" onClick={this.setSorting.bind(this, "moveout", this.sortLeasesUpTime("actual_move_out"))}>
                    <i className="fas fa-caret-down pt-1 ml-1"/>
                  </a>
                  : <a className="ml-1" onClick={this.setSorting.bind(this, "moveout", this.sortLeasesDownTime("actual_move_out"))}>
                    <i className="fas fa-caret-up pt-1 ml-1"/>
                  </a>}
            </th>
            <th>Rent</th>
          </tr>
          </thead>
            {this.filter()}
        </table>
      </CardBody>
    </Card>
  }
}


export default connect(({property, properties, leases, dates}) => {
  return {property, properties, leases, dates}
})(ReportsApp)
