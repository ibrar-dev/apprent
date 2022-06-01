import React from 'react';
import Group from './group';
import {Table, Button, Row, Col} from 'reactstrap'

function ExpandButtons(props) {
  return <Row>
    <Col>
      <Button className="pl-0" onClick={() => props.toggleCollapse(true)} color='link'>collapse all</Button>
      <Button onClick={() => props.toggleCollapse(false)} color='link'>expand all</Button>
    </Col>
  </Row>
}

class BudgetComparison extends React.Component {
  state = {collapsed: false, serial: 0};

  toggleCollapse(bool) {
    this.setState({collapsed: bool, serial: this.state.serial + 1})
  }

  render() {
    const {result, suppressZeros} = this.props;
    const {collapsed, serial} = this.state;
    return <>
      <ExpandButtons toggleCollapse={this.toggleCollapse.bind(this)}/>
      <div id="report-data">
        <Table bordered size="sm">
          <thead>
          <tr className="table-active">
            <th>Account</th>
            <th>PTD Actual</th>
            <th>PTD Budget</th>
            <th>Variance</th>
            <th>% Var</th>
            <th>YTD Actual</th>
            <th>YTD Budget</th>
            <th>Variance</th>
            <th>% Var</th>
            <th>Annual</th>
          </tr>
          </thead>
          <tbody>
          {result.map((g, i) => (
            <Group collapsed={collapsed} serial={serial} group={g} key={i} level={0} suppressZeros={suppressZeros}/>
          ))}
          </tbody>
        </Table>
      </div>
    </>
  }
}

export default BudgetComparison;
