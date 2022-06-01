import React, {Component, Fragment} from 'react';
import {connect} from "react-redux";
import {Row, Col, Table, Input} from 'reactstrap';
import {withRouter} from 'react-router';
import {Link} from 'react-router-dom';
import moment from 'moment';
import DetailedLogs from './detailedLogs';
import 'react-dates/initialize';
import {DateRangePicker} from 'react-dates';
import isInclusivelyBeforeDay from 'react-dates/lib/utils/isInclusivelyAfterDay';
import actions from '../actions';

class Report extends Component {
  constructor(props) {
    super(props);
    let regex = /\d+/;
    const stock_id = props.history.location.pathname.match(regex)[0];
    this.state = {startDate: moment().subtract(7, 'days'), endDate: moment(), filterVal: ''};
    actions.fetchStock(stock_id);
    actions.fetchStockInventory(stock_id, moment().subtract(7, 'days').format("YYYY-MM-DD"), moment().format("YYYY-MM-DD"));
  };

  _extractTotalDollahs(logs) {
    return logs.reduce((sum, l) => sum + (l.material_cost * l.quantity), 0);
  }

  toggleDetails() {
    this.setState({...this.state, detailed: !this.state.detailed});
  }

  setActive(t) {
    this.setState({...this.state, activeType: t, detailed: !this.state.detailed});
  }

  changeDates({startDate, endDate}) {
      if (endDate ) {
        const start_date = moment(startDate).format("YYYY-MM-DD");
        const end_date = moment(endDate).format("YYYY-MM-DD");
        end_date > "2018-10-23" ? actions.fetchStockInventory(this.props.stock.id, start_date, end_date) : actions.fetchMaterialLogs(this.props.stock.id, start_date, end_date)
      }
      this.setState({startDate, endDate});
    }


  updateFilter(e) {
    this.setState({...this.state, filterVal: e.target.value})
  }

  toShow(logs) {
    const regex = new RegExp(this.state.filterVal, 'i');
    return logs.filter(l => regex.test(l.property))
  }

  render() {
    const {logs} = this.props;
    const {detailed, activeType, startDate, endDate, focusedInput} = this.state;
    let sum = 0;
    let sum2 = 0;
    return <Fragment>
      <Row>
        <Col>
          <Table hover>
            <thead>
              <tr>
                <th className="align-middle nowrap"><
                  Link to="/materials" className="btn btn-danger mr-1">
                    <i className="fas fa-arrow-left"/>
                  </Link>
                </th>
                <th>Category</th>
                <th>Movement</th>
                <th>Total</th>
                <th>
                  <DateRangePicker startDate={startDate}
                                   endDate={endDate}
                                   startDateId="start-timecard-date-id"
                                   endDateId="end-timecard-date-id"
                                   focusedInput={focusedInput}
                                   minimumNights={0}
                                   isOutsideRange={day => isInclusivelyBeforeDay(day, moment().add(1, 'days'))}
                                   onFocusChange={focusedInput => this.setState({ focusedInput })}
                                   onDatesChange={this.changeDates.bind(this)}/>
                </th>
                <th className='form-group'>
                  <Input placeholder="Property" name="propertyFilter" onChange={this.updateFilter.bind(this)} />
                </th>
              </tr>
            </thead>
            <tbody>
              {logs && logs.map(c => {
                sum = sum + Math.round(this._extractTotalDollahs(this.toShow(c.logs)) * 100) / 100;
                  sum2 = sum2 + this.toShow(c.logs).length;
                return <tr key={c.id} onClick={this.setActive.bind(this, c)}>
                  <td/>
                  <td>{c.name}</td>
                  <td>{this.toShow(c.logs).length}</td>
                  <td><b>${Math.round(this._extractTotalDollahs(this.toShow(c.logs)) * 100) / 100}</b></td>
                  <td/>
                  <td/>
                </tr>
              })}
              <tr>
                  <td/>
                  <td><b>Sum</b></td>
                  <td><b>{sum2}</b></td>
                  <td><b>${sum}</b></td>
                  <td/>
                  <td/>
              </tr>
            </tbody>
          </Table>
        </Col>
      </Row>
      {detailed && activeType && <DetailedLogs toggle={this.toggleDetails.bind(this)} open={detailed} startDate={startDate} endDate={endDate} name={activeType.name} logs={this.toShow(activeType.logs)} />}
    </Fragment>
  }
}

export default withRouter(connect(({logs, stock}) => {
  return {logs, stock};
})(Report));