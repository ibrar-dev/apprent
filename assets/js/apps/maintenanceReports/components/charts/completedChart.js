import React, {Component} from 'react';
import {connect} from "react-redux";
import moment from "moment";
import {Line} from 'react-chartjs-2';
import {Button, Row, Col, Collapse, Card} from 'reactstrap';
import colors from "../../../usageDashboard/components/colors";

const reducedProperties = (completedOrders) => {
  let properties = {};
  completedOrders.forEach(o => {
    if (o.property.name === 'Dasmen Sandbox') return;
    if (properties[o.property.name]) return properties[o.property.name].push({date: o.completion_date, id: o.id});
    if (!properties[o.property.name]) {
      properties[o.property.name] = [];
      return properties[o.property.name].push({date: o.completion_date, id: o.id})
    }
  });
  return properties;
};

const propertiesList = (completedOrders) => {
  let properties = [];
  completedOrders.forEach(o => {
    if (o.property.name === 'Dasmen Sandbox') return;
    if (properties.indexOf(o.property.name) === -1) return properties.push(o.property.name);
  });
  return properties;
}

const options = (title) => {
  return {
    plugins: {
      labels: {
        render: 'label'
      }
    },
    title: {
      display: true,
      text: title,
    }
  };
};

const lineChartData = (propertyList, viewList) => {
  const length = Object.keys(propertyList).length;
  let data = {
    datasets: [],
    labels: []
  };
  Object.keys(propertyList).map((k, i) => {
    const col = colors(i, length);
    propertyList[k].forEach(o => {
      if (data.labels.indexOf(moment(o.date).format("MM-DD-YY")) === -1) return data.labels.push(moment(o.date).format("MM-DD-YY"));
    });
    let propData = data.labels.map(l => {
      let total = propertyList[k].filter(o => moment(o.date).format("MM-DD-YY") === l).length;
      return {x: l, y: total}
    });
    const hidden = (viewList.includes(k) || viewList.length === 0) ? false : true;
    propData.sort((a, b) => moment(a.x).diff(moment(b.x)));
    data.datasets.push({label: k, data: propData, backgroundColor: col.replace(/, .*\)/, ',0.5)'), borderColor: col, hidden: hidden})
  });
  data.labels.sort((a, b) => moment(a).diff(moment(b)));
  return data;
}

class CompletedChart extends Component {
  state = {
    totals: false,
    viewList: []
  }

  toggleTotals() {
    this.setState({...this.state, totals: !this.state.totals});
  }

  adjustPropertyList(p) {
    let {viewList} = this.state;
    if (viewList.indexOf(p) === -1) {
      viewList.push(p);
    } else {
      viewList.splice(viewList.indexOf(p), 1)
    };
    this.setState({...this.state, viewList});
  }

  render() {
    const {completedOrders} = this.props;
    const {totals, viewList} = this.state;
    const data = lineChartData(reducedProperties(completedOrders), viewList);
    return <Row>
      <Col sm={12}>
        <Row>
          <Col sm={12} className="mt-1">
            <Button active={totals} onClick={this.toggleTotals.bind(this)} outline color="info" size="sm">{totals ? 'Hide' : 'View'} Totals</Button>
          </Col>
        </Row>
        <Collapse isOpen={totals}>
          <Row className="mt-1">
            {propertiesList(completedOrders).map((k, i) => {
              return <Col sm={2} key={i}>
                <Card onClick={this.adjustPropertyList.bind(this, k)} body style={{backgroundColor: data.datasets[i].backgroundColor, borderColor: data.datasets[i].borderColor, cursor: 'pointer', boxShadow: viewList.includes(k) ? ' 0 14px 28px rgba(0,0,0,0.25), 0 10px 10px rgba(0,0,0,0.22)' : ''}}>
                  <span className="d-flex justify-content-between">
                    <b>{k}</b>
                    <span>{reducedProperties(completedOrders)[k].length}</span>
                  </span>
                </Card>
              </Col>
            })}
          </Row>
        </Collapse>
        <Row>
          <Line data={data} options={{...options("Orders Completed (By Property)")}} />
        </Row>
      </Col>
    </Row>
  }
}

export default connect(({completedOrders}) => {
  return {completedOrders}
})(CompletedChart)