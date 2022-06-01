import React, {Component} from 'react';
import {Row, Col, Card, CardBody, Table} from 'reactstrap';
import DatePicker from '../../../../../components/datePicker';
import isInclusivelyBeforeDay from "react-dates/lib/utils/isInclusivelyBeforeDay";
import moment from "moment";

class Basics extends Component {
  updateDateParams(field, val) {
    this.props.onChange(field, val);
  }

  render() {
    const {lease} = this.props;
    return <div>
      <Row>
        <Col md={5}>
          <Card>
            <CardBody>
              <div className="d-flex flex-column form-group">
                <h5>
                  Date of Lease
                </h5>
                <DatePicker value={lease.lease_date}
                            disabled={lease.locked}
                            isOutsideRange={day => isInclusivelyBeforeDay(day, moment().subtract(1, 'days'))}
                            onChange={this.updateDateParams.bind(this, "lease_date")}/>
                <small className="form-text text-muted">This is not the lease start date, this is the date the lease was
                  first created.
                </small>
              </div>
            </CardBody>
          </Card>
        </Col>
        <Col md={7}>
          <Card>
            <CardBody>
              <div className="d-flex flex-column form-group">
                <div className="d-flex justify-content-between align-items-center mb-3">
                  <h5 className="m-0">
                    People
                  </h5>
                  <a className="btn btn-info" href={`/applications/${lease.application_id}/edit`} target="_blank">
                    Edit Application
                  </a>
                </div>
                <Table>
                  <thead>
                  <tr>
                    <th>Name</th>
                    <th>Status</th>
                  </tr>
                  </thead>
                  <tbody>
                  {lease.persons.map(p => {
                    return <tr key={p.id}>
                      <td>{p.full_name}</td>
                      <td>{p.status}</td>
                    </tr>
                  })}
                  </tbody>
                </Table>
              </div>
            </CardBody>
          </Card>
        </Col>
      </Row>
    </div>
  }
}

export default Basics;