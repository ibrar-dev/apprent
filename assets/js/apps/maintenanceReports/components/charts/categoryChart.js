import React, {Component} from 'react';
import {connect} from 'react-redux';
import {Button, ButtonGroup, Row, Col} from 'reactstrap';
import 'react-dates/initialize';
import {DateRangePicker} from "react-dates";
import isInclusivelyBeforeDay from "react-dates/lib/utils/isInclusivelyAfterDay";
import moment from "moment";
import actions from "../../actions";
import CreatedCategories from './createdCategoryChart';
import CompletedCategories from './completedCategoriesChart';

class CategoryChart extends Component {
  constructor(props) {
    super(props);
    this.state = {
      activeTab: 'completed',
      startDate: moment().startOf('month'),
      endDate: moment()
    },
    actions.fetchCategoriesCompleted(moment().startOf('month').format("YYYY-MM-DD"), moment().format("YYYY-MM-DD"));
  }

  setDates({startDate, endDate}) {
    this.setState({...this.state, startDate, endDate}, this.fetchInfo);
  }

  setActiveTab(val) {
    this.setState({...this.state, activeTab: val}, this.fetchInfo);
  }

  fetchInfo() {
    const {activeTab, startDate, endDate} = this.state;
    if (activeTab === 'created') return actions.fetchCategories(moment(startDate).format("YYYY-MM-DD"), moment(endDate).format("YYYY-MM-DD"));
    if (activeTab === 'completed') return actions.fetchCategoriesCompleted(moment(startDate).format("YYYY-MM-DD"), moment(endDate).format("YYYY-MM-DD"));
  }

  render() {
    const {categoriesOrders, categoriesCompleted} = this.props;
    const {startDate, endDate, focusedInput, activeTab} = this.state;
    return <Row>
      <Col sm={12} className="d-flex justify-content-between">
        <ButtonGroup>
          <Button onClick={this.setActiveTab.bind(this, 'created')} size="sm" outline color="info" active={activeTab === 'created'}>Created</Button>
          <Button onClick={this.setActiveTab.bind(this, 'completed')} size="sm" outline color="info" active={activeTab === 'completed'}>Completed</Button>
        </ButtonGroup>
        <DateRangePicker startDate={startDate}
                         endDate={endDate}
                         startDateId="start-timecard-date-id"
                         endDateId="end-timecard-date-id"
                         focusedInput={focusedInput}
                         minimumNights={0}
                         small
                         isOutsideRange={day => isInclusivelyBeforeDay(day, moment().add(1, 'days'))}
                         onFocusChange={focusedInput => this.setState({focusedInput})}
                         onDatesChange={this.setDates.bind(this)}/>
      </Col>
      <Col sm={12}>
        {activeTab === 'created' && <CreatedCategories categoriesOrders={categoriesOrders} />}
        {activeTab === 'completed' && <CompletedCategories dates={{startDate, endDate}} categoriesCompleted={categoriesCompleted} />}
      </Col>
    </Row>
  }
}

export default connect(({categoriesOrders, categoriesCompleted}) => {
  return {categoriesOrders, categoriesCompleted}
})(CategoryChart);