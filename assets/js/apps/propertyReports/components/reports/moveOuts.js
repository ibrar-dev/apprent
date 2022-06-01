import React from 'react';
import {connect} from 'react-redux';
import {Card, CardBody, CardHeader, Table} from 'reactstrap';
import DateRangePicker from '../../../../components/dateRangePicker';
import actions from '../../actions';

class MoveOuts extends React.Component {
  state = {};

  componentWillReceiveProps(nextProps, nextContext) {
    if (nextProps.property.id !== this.props.property.id) {
      const {startDate, endDate} = this.state;
      actions.fetchMultiDateReport('move_outs', nextProps.property, startDate.format('YYYY-MM-DD'), endDate.format('YYYY-MM-DD'));
    }
  }

  changeDates({startDate, endDate}) {
    this.setState({startDate, endDate});
    if (startDate && endDate) {
      const {property} = this.props;
      actions.fetchMultiDateReport('move_outs', property, startDate.format('YYYY-MM-DD'), endDate.format('YYYY-MM-DD'));
    }
  }

  render() {
    const {startDate, endDate} = this.state;
    const {reportData} = this.props;
    let total = 0;
    reportData.forEach(r => total += r.count);
    return <Card>
      <CardHeader className="d-flex justify-content-between align-items-center">
        <div>Move Outs</div>
        <div>
          <DateRangePicker startDate={startDate} endDate={endDate} onDatesChange={this.changeDates.bind(this)}/>
        </div>
      </CardHeader>
      <CardBody className="p-0">
        <Table className="m-0">
          <thead>
          <tr>
            <th>
              Reason
            </th>
            <th>
              Number
            </th>
            <th>
              Percentage
            </th>
          </tr>
          </thead>
          <tbody>
          {reportData.map(row => {
            return <tr key={row.id}>
              <td>{row.name}</td>
              <td>{row.count}</td>
              <td>{Math.round(row.count * 1000.0 / total) / 10}%</td>
            </tr>
          })}
          </tbody>
        </Table>
      </CardBody>
    </Card>
  }
}

export default connect(({reportData, property}) => {
  return {reportData, property};
})(MoveOuts);