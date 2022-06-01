import React, {Component} from 'react';
import {connect} from 'react-redux';
import {Row, Col, CardBody} from 'reactstrap';

class RegionalReport extends Component {
  state = {};

  render() {
    const {report} = this.props;
    return <Row className="mb-2">
      <Col>
        <CardBody id="approval-card"
                  className="d-flex align-items-center flex-column v-align-middle border border-primary">
          <div>Pending Approvals</div>
          <h3>{report.pending_periods && report.pending_periods}</h3>
        </CardBody>
      </Col>
      <Col>
        <CardBody className="d-flex align-items-center flex-column v-align-middle border border-primary">
          <span>Leases Needing Renewals</span>
          <h3>{report.leases_needing_renewals && report.leases_needing_renewals}</h3>
        </CardBody>
      </Col>
      {/*<Col>*/}
      {/*  <CardBody className="d-flex align-items-center flex-column v-align-middle border border-primary">*/}
      {/*    <span>Most Common</span>*/}
      {/*    <h3>8</h3>*/}
      {/*  </CardBody>*/}
      {/*</Col>*/}
    </Row>
  }
}

export default connect(({report}) => {
  return {report}
})(RegionalReport)