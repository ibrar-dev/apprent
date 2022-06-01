import React, {Component, Fragment} from 'react';
import {Col, Row, Collapse, Card, CardHeader, CardFooter, CardBody} from "reactstrap";
import {Doughnut} from "react-chartjs-2";
import moment from 'moment';
import colors from "../../../usageDashboard/components/colors";

const chartData = (orders) => {
  let data = {
    datasets: [{
      backgroundColor: [],
      data: []
    }],
    labels: [],
    colors: []
  }
  orders.forEach(o => {
    if (data.labels.indexOf(o.category) === -1) data.labels.push(o.category);
  });
  const length = data.labels.length;
  data.labels.forEach((l, i) => {
    const col = colors(i, length);
    data.datasets[0].backgroundColor.push(col);
    let total = orders.filter(o => o.category === l).length;
    data.datasets[0].data.push(total)
  });
  return data;
};

const scChartData = (orders, category) => {
  let data = {
    datasets: [{
      backgroundColor: [],
      data: []
    }],
    labels: [],
    colors: []
  };
  const filteredOrders = orders.filter(o => o.category === category);
  filteredOrders.forEach(o => {
    if (data.labels.indexOf(o.subcategory) === -1) data.labels.push(o.subcategory);
  });
  const length = data.labels.length;
  data.labels.forEach((l, i) => {
    const col = colors(i, length);
    data.datasets[0].backgroundColor.push(col);
    let total = filteredOrders.filter(o => o.subcategory === l).length;
    data.datasets[0].data.push(total)
  });
  return data;
};

const filteredCatOrders = (orders, category) => {
  return orders.filter(o => o.category === category)
}

const filteredSCOrders = (orders, subCategory) => {
  return orders.filter(o => o.subcategory === subCategory)
}

const options = (title) => {
  return {
    plugins: {
      labels: {
        render: 'label',
      }
    },
    title: {
      display: true,
      text: title,
    }
  };
};

class CompletedCategories extends Component {
  state = {}

  clicked(e) {
    const labels = chartData(this.props.categoriesCompleted).labels;
    e.length >= 1 ? this.setState({...this.state, activeCat: labels[(e[0]._index)], activeSC: null}) : this.setState({...this.state, activeCat: null, activeSC: null})
  }

  scClicked(e) {
    const labels = scChartData(this.props.categoriesCompleted, this.state.activeCat).labels;
    e.length >= 1 ? this.setState({...this.state, activeSC: labels[(e[0]._index)]}) : this.setState({...this.state, activeSC: null})
  }

  calculateAvg(orders) {
    let total = orders.reduce((acc, o) => moment(o.completed_at).diff(moment(o.inserted_at)) + acc, 0) / orders.length;
    return moment.duration(total).asDays().toFixed(2);
  }

  render() {
    const {categoriesCompleted, dates: {startDate, endDate}} = this.props;
    const {activeCat, activeSC} = this.state;
    return <Fragment>
      <Row>
        <Col lg={6}>
          <Doughnut data={chartData(categoriesCompleted)} getElementAtEvent={this.clicked.bind(this)} options={{...options("Orders Completed (By Category)")}} />
        </Col>
        <Col lg={6}>
          {activeCat && <Doughnut data={scChartData(categoriesCompleted, activeCat)} getElementAtEvent={this.scClicked.bind(this)} options={{...options(`${activeCat} Orders Completed`)}} />}
        </Col>
      </Row>
      <Collapse isOpen={activeCat != null}>
        <Row className="mt-2">
          <Col sm={12}>
            <Card>
              <CardHeader>
                From {moment(startDate).format("dddd, MMMM Do YYYY")} to {moment(endDate).format("dddd, MMMM Do YYYY")}{" "}
                there were <b>{filteredCatOrders(categoriesCompleted, activeCat).length} {activeCat}</b> orders completed
                {activeSC && <Fragment> and <b>{filteredSCOrders(categoriesCompleted, activeSC).length}</b> <b>{activeSC}</b> orders completed.</Fragment>}
                {!activeSC && <Fragment>.</Fragment>}
              </CardHeader>
              <CardBody className="d-flex flex-column">
                <div>
                  <b>{activeCat}</b> Avg. Completion Time: <b>{this.calculateAvg(filteredCatOrders(categoriesCompleted, activeCat))}</b> days.
                </div>
                {activeSC && <div>
                  <b>{activeSC}</b> Avg. Completion Time: <b>{this.calculateAvg(filteredSCOrders(categoriesCompleted, activeSC))}</b> days.
                </div>}
              </CardBody>
            </Card>
          </Col>
        </Row>
      </Collapse>
    </Fragment>
  }
}

export default CompletedCategories;