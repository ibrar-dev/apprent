import React, {Component} from 'react';
import colors from "../../../usageDashboard/components/colors";
import {Col, Row} from "reactstrap";
import {Doughnut} from "react-chartjs-2";

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

class CreatedCategories extends Component {
  state = {};

  clicked(e) {
    const labels = chartData(this.props.categoriesOrders).labels;
    e.length >= 1 ? this.setState({...this.state, active: labels[(e[0]._index)]}) : this.setState({...this.state, active: null})
  }

  render() {
    const {categoriesOrders} = this.props;
    const {active} = this.state;
    return <Row>
      <Col lg={6}>
        <Doughnut data={chartData(categoriesOrders)} getElementAtEvent={this.clicked.bind(this)} options={{...options("Orders Created (By Category)")}} />
      </Col>
      <Col lg={6}>
        {active && <Doughnut data={scChartData(categoriesOrders, active)} options={{...options(`${active} Orders Created`)}} />}
      </Col>
    </Row>
  }
}

export default CreatedCategories;