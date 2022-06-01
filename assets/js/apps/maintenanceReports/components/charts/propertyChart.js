import React, {Component} from 'react';
import {connect} from 'react-redux';
import {Button, ButtonGroup, Row, Col} from 'reactstrap';
import 'react-dates/initialize';
import {DateRangePicker} from "react-dates";
import isInclusivelyBeforeDay from "react-dates/lib/utils/isInclusivelyAfterDay";
import moment from "moment";
import actions from '../../actions';
import OpenChart from './openHistoriesChart';
import CompletedChart from './completedChart';
import KatsReport from './katsReport';
import MakeReadyReport from './makeReadyReport';
import Synopsis from './synopsisChart';

class PropertyChart extends Component {
  constructor(props) {
    super(props);
    this.state = {
      active: 'open',
      startDate: moment().startOf('month'),
      endDate: moment()
    },
    actions.fetchOpenHistories(
      moment().startOf('month').format("YYYY-MM-DD"),
      moment().format("YYYY-MM-DD")
    );
  }

  setDates({startDate, endDate}) {
    this.setState({...this.state, startDate, endDate}, this.fetchInfo);
  }

  fetchInfo() {
    const {active, startDate, endDate} = this.state;
    if (active === 'open') {
      return actions.fetchOpenHistories(
        moment(startDate).format("YYYY-MM-DD"),
        moment(endDate).format("YYYY-MM-DD")
      );
    }
    if (active === 'completed') {
      return actions.fetchCompletedOrders(
        moment(startDate).format("YYYY-MM-DD"),
        moment(endDate).format("YYYY-MM-DD")
      );
    }
    if (active === 'kat') {
      return actions.fetchKatsReport(
        moment(endDate).format("YYYY-MM-DD")
    );
    }
    if (active === 'makeReady') {
      return actions.fetchDatedReport(
        'makeReadyReport',
        moment(startDate).format("YYYY-MM-DD"),
        moment(endDate).format("YYYY-MM-DD")
      );
    }
  }

  setActive(val) {
    this.setState({...this.state, active: val}, this.fetchInfo);
  }

  render() {
    const {propertyList} = this.props;
    const {startDate, endDate, focusedInput, active} = this.state;
    return <Row>
      <Col sm={12} className="d-flex justify-content-between">
        <ButtonGroup>
          <Button
            onClick={this.setActive.bind(this, 'completed')}
            size="sm"
            outline
            color="info"
            active={active === 'completed'}
          >
            Completed Orders
          </Button>
          <Button
            onClick={this.setActive.bind(this, 'open')}
            size="sm"
            outline
            color="info"
            active={active === 'open'}
          >
            Open History
          </Button>
          <Button
            onClick={this.setActive.bind(this, 'kat')}
            size="sm"
            outline
            color="info"
            active={active === 'kat'}
          >
            Kat's Report
          </Button>
          <Button
            onClick={this.setActive.bind(this, 'makeReady')}
            size="sm"
            outline color="info"
            active={active === 'makeReady'}
          >
            Make Readies
          </Button>
          <Button
            onClick={this.setActive.bind(this, 'synopsis')}
            size="sm"
            outline
            color="info"
            active={active === 'synopsis'}
          >
            Synopsis
          </Button>
        </ButtonGroup>
        {active !== 'synopsis' &&
            <DateRangePicker
              startDate={startDate}
              endDate={endDate}
              startDateId="start-timecard-date-id"
              endDateId="end-timecard-date-id"
              focusedInput={focusedInput}
              minimumNights={0}
              small
              isOutsideRange={day => isInclusivelyBeforeDay(day, moment().add(1, 'days'))}
              onFocusChange={focusedInput => this.setState({focusedInput})}
              onDatesChange={this.setDates.bind(this)}
            />
        }
      </Col>
      <Col sm={12}>
        {active === 'open' && <OpenChart />}
        {active === 'completed' && <CompletedChart propertyList={propertyList} />}
        {active === 'kat' && <KatsReport propertyList={propertyList} />}
        {active === 'makeReady' && <MakeReadyReport propertyList={propertyList} />}
        {active === 'synopsis' && <Synopsis />}
      </Col>
    </Row>
  }
}

export default connect(({properties}) => {
  return {properties}
})(PropertyChart);
