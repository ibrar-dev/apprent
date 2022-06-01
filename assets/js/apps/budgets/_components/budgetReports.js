import React, {Component} from 'react';
import {connect} from "react-redux";
import {Card, Row, Col, CardHeader, CardBody} from 'reactstrap';

class BudgetReport extends Component {

  render() {
    return <Row>
      <Col>
        <Card>
          <CardHeader>Budget Reports</CardHeader>.
          <CardBody>
            <Row>
              <Col></Col>
            </Row>
          </CardBody>
        </Card>
      </Col>
    </Row>
  }
}

export default connect(({}) => {
  return {}
})(BudgetReport)