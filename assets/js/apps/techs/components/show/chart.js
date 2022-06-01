import React from 'react';
import {Pie, Doughnut} from 'react-chartjs-2';
import {Row, Col} from 'reactstrap';


const chartData = (sortedAssignments) => {
  let data1 = [];
  let labels = Object.keys(sortedAssignments);
  let data2 = Object.values(sortedAssignments);
  data2.forEach(d => {
    data1.push(d.length)
  });
  return {
    datasets: [{
      data: data1,
      backgroundColor: ["#0fedae", "#4fa4ff", "#ffd416", "#98c46a"]
    }],
    labels: labels
  };
};

class Chart extends React.Component {
  state = {
    items: []
  }

  componentWillMount() {
    this.sortItems(this.props.items, this.props.dates);
  }

  sortItems(items) {
    if (items.length >= 1) {
      const sorted = {pending: [], checked_out: [], ordered: [], returned: []};
      const shopSorted = {};
      items.forEach(i => {
        sorted[i.status].push(i);
        if (shopSorted[i.stock]) return shopSorted[i.stock].push(i);
        shopSorted[i.stock] = [];
        shopSorted[i.stock].push(i);
      });
      this.setState({...this.state, items: sorted, shopItems: shopSorted});
    }
  }

  render() {
    const {items, shopItems} = this.state;
    return <Row>
      <Col lg={6} md={12} className="d-flex justify-content-between">
        <Doughnut data={chartData(items)} />
      </Col>
      <Col lg={6} md={12}>
        <Pie data={chartData(shopItems)} />
      </Col>
    </Row>
  }
}

export default Chart;