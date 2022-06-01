import React, {Component} from 'react';
import {connect} from 'react-redux';
import {Row, Col, Input} from 'reactstrap';
import 'react-dates/initialize';
import moment from "moment";
import actions from '../../actions';
import Select from '../../../../components/select'
import Pagination from '../../../../components/pagination'
import UnitRow from "./unitRow";
import iconButton from './pdfExport';


class UnitsChart extends Component {
  constructor(props) {
    super(props);
    this.state = {
      active: 'open',
      startDate: moment().startOf('month'),
      endDate: moment()
    };
    // actions.fetchOpenHistories(moment().startOf('month').format("YYYY-MM-DD"), moment().format("YYYY-MM-DD"));
  }

  setDates({startDate, endDate}) {
    this.setState({...this.state, startDate, endDate}, this.fetchInfo);
  }

  change({target: {value}}) {
    this.setState({...this.state, property: value});
    actions.fetchUnits(value)
  }

  changeFilter(e) {
    this.setState({...this.state, filterVal: e.target.value});
  }

  changeSort({target: {value}}) {
    this.setState({...this.state, sortVal: value});
  }

  _filters() {
    const {filterVal, sortVal} = this.state;
    const sortOptions = [{label: "Orders ↑", value: 2}, {label: "Orders ↓", value: 3}];
    return <div className="d-flex">
      <Input value={filterVal} onChange={this.changeFilter.bind(this)} style={{marginRight: 8}}/>
      <Select value={sortVal}
              className="w-100"
              placeholder='sort'
              options={sortOptions}
              onChange={this.changeSort.bind(this)}/>
    </div>
  }

  filtered() {
    const {filterVal, sortVal} = this.state;
    const {units, orders} = this.props;
    const regex = new RegExp(filterVal, 'i');
    let filtered = []
    if (units.length) filtered = units.filter(u => u.number.match(regex))
    let mapped = filtered.map(u => {
      let unitOrders = [];
      if (orders.length) unitOrders = orders.filter(o => o.unit_id === u.id);
      return {details:u, orders: unitOrders}
    })
    return mapped.sort((a, b) => {
      switch (sortVal) {
        case 0:
          return a.details.number > b.details.number;
        case 1:
          return a.details.number < b.details.number;
        case 2:
          return b.orders.length - a.orders.length;
        case 3:
          return a.orders.length - b.orders.length;
        default:
          return true;
      }
    });
  }

  render() {
    const {properties} = this.props;
    const {property} = this.state;
    const propertyOptions = properties.map(x => {
      return {label: x.name, value: x.id}
    });
    return <Col>
      <Row className="d-flex justify-content-between">
        <div className="d-flex justify-content-start" style={{minWidth: 200}}>
          <Select value={property}
                  className="w-100"
                  placeholder='Select Property'
                  options={propertyOptions}
                  onChange={this.change.bind(this)}/>
        </div>
      </Row>
      <Row style={{paddingTop: 20}}>
        <Pagination
          title="Units"
          type="row"
          tableClasses="p-3"
          collection={this.filtered()}
          component={UnitRow}
          filters={this._filters()}
          field="unit"
          className={"flex-grow-1"}
        />
      </Row>
    </Col>
  }
}

export default connect(({properties, units, orders}) => {
  return {properties, units, orders}
})(UnitsChart);
