import React, {Component} from 'react';
import moment from 'moment';
import {Row, Col, Button, Collapse, Card} from 'reactstrap';
import {connect} from 'react-redux';
import {Line} from 'react-chartjs-2';
import colors from '../../../usageDashboard/components/colors';

const reducedProperties = (historyList) => {
  let properties = {};
  historyList.forEach(h => {
    if (h.property.name === 'Dasmen Sandbox') return;
    if (properties[h.property.name]) return properties[h.property.name].push({date: h.date, open: h.open});
    if (!properties[h.property.name]) {
      properties[h.property.name] = [];
      return properties[h.property.name].push({date: h.date, open: h.open, id: h.id})
    }
  });
  return properties;
};

const lineChartData = (propertyList) => {
  const length = Object.keys(propertyList).length;
  let data = {
    datasets: [],
    labels: []
  };
  Object.keys(propertyList).map((k, i) => {
    const col = colors(i, length);
    let propData = propertyList[k].map(h => {
      if (data.labels.indexOf(moment.utc(h.date).format("MM-DD-YY")) === -1) data.labels.push(moment.utc(h.date).format("MM-DD-YY"));
      return {x: moment.utc(h.date).format("MM-DD-YY"), y: h.open}
    });
    data.datasets.push({label: k, data: propData, backgroundColor: col.replace(/, .*\)/, ',0.5)'), borderColor: col})
  })
  return data;
};

class OpenChart extends Component {
  state = {
    breakdown: false
  }

  toggleKatReport() {
    this.setState({...this.state, breakdown: !this.state.breakdown});
  }

  render() {
    const {openHistories} = this.props;
    const data = lineChartData(reducedProperties(openHistories));
    return <Row>
      <Col xs={12}>
        <Row>
          <Line data={data}/>
        </Row>
      </Col>
    </Row>
  }
}

export default connect(({openHistories, katsReport}) => {
  return {openHistories, katsReport}
})(OpenChart);