import React from 'react';
import {Row, Col} from 'reactstrap';
import moment from 'moment';
import Rating from '../rating';

const statusKey = {
  completed: 'success',
  in_progress: 'warning',
  callback: 'danger',
  pending: 'info'
};

class Assignments extends React.Component {
  state = {};

  render() {
    const {tech, assignments, orders, active} = this.props;
    console.log(assignments)
    return <Row>
      <Col md={6}>
        {(active === "completed" || !active) && assignments.completed && assignments.completed.length >= 1 && <React.Fragment>
          <h3>Completed</h3>
          <ul className="list-unstyled">
          {assignments.completed && assignments.completed.map(a => {
            return <li className="list-group-item" key={a.id}>
              <div className="d-flex justify-content-between">
                <div className="w-50">
                  <div><b>{a.order.tenant}</b></div>
                  <div>Received {moment.utc(a.order.submitted).local().format("YYYY-MM-DD")}</div>
                  <div>Assigned {moment.utc(a.inserted_at).local().format("YYYY-MM-DD")}</div>
                  <div>Completed {moment.utc(a.completed_at).local().format("YYYY-MM-DD")}</div>
                </div>
                <div className="w-50">
                  <div>{a.order.property} Unit {a.order.unit}</div>
                  <div>{a.order.category}</div>
                  <div>Status: <span className={`position-static badge badge-${statusKey[a.status]}`}>{a.status.replace('_', ' ')}</span> </div>
                  <div>{a.rating ? <Rating rating={a.rating}/> : 'Not Rated'}</div>
                </div>
              </div>
            </li>
            })}
          </ul>
        </React.Fragment>}
      </Col>
      <Col md={6}>
        {(active === "in_progress" || !active) && assignments.in_progress && assignments.in_progress.length >= 1 && <React.Fragment>
          <h3>Active</h3>
          <ul className="list-unstyled">
            {assignments.in_progress && assignments.in_progress.map(a => {
              return <li className="list-group-item" key={a.id}>
                <div className="d-flex justify-content-between">
                  <div className="w-50">
                    <div><b>{a.order.tenant}</b></div>
                    <div>Received {moment.utc(a.order.submitted).local().format("YYYY-MM-DD")}</div>
                    <div>Assigned {moment.utc(a.inserted_at).local().format("YYYY-MM-DD")}</div>
                  </div>
                  <div className="w-50">
                    <div>{a.order.property.name} Unit {a.order.unit}</div>
                    <div>{a.order.category}</div>
                    <div>Status: <span className={`position-static badge badge-${statusKey[a.status]}`}>{a.status.replace('_', ' ')}</span> </div>
                    <div>{a.rating ? <Rating rating={a.rating}/> : 'Not Rated'}</div>
                  </div>
                </div>
              </li>
            })}
          </ul>
        </React.Fragment>}
        {(active === "on_hold" || !active) && assignments.on_hold && assignments.on_hold.length >= 1 && <React.Fragment>
          <h3>Paused</h3>
          <ul className="list-unstyled">
            {assignments.on_hold && assignments.on_hold.map(a => {
              return <li className="list-group-item" key={a.id}>
                <div className="d-flex justify-content-between">
                  <div className="w-50">
                    <div><b>{a.order.tenant}</b></div>
                    <div>Received {moment.utc(a.order.submitted).local().format("YYYY-MM-DD")}</div>
                    <div>Assigned {moment.utc(a.inserted_at).local().format("YYYY-MM-DD")}</div>
                  </div>
                  <div className="w-50">
                    <div>{a.order.property} Unit {a.order.unit}</div>
                    <div>{a.order.category}</div>
                    <div>Status: <span className={`position-static badge badge-${statusKey[a.status]}`}>{a.status.replace('_', ' ')}</span> </div>
                    <div>{a.rating ? <Rating rating={a.rating}/> : 'Not Rated'}</div>
                  </div>
                </div>
              </li>
            })}
          </ul>
        </React.Fragment>}
        {(active === "callback" || !active) && assignments.callback && assignments.callback.length >= 1 && <React.Fragment>
          <h3>Callbacks</h3>
          <ul className="list-unstyled">
          {assignments.callback && assignments.callback.map(a => {
            return <li className="list-group-item alert-danger" key={a.id}>
              <div className="d-flex justify-content-between">
                <div className="w-50">
                  <div><b>{a.order.tenant}</b></div>
                  <div>Received {moment.utc(a.order.submitted).local().format("YYYY-MM-DD")}</div>
                  <div>Assigned {moment.utc(a.inserted_at).local().format("YYYY-MM-DD")}</div>
                  <div>Called Back {moment.utc(a.updated_at).local().format("YYYY-MM-DD")}</div>
                </div>
                <div className="w-50">
                  <div>{a.order.property} Unit {a.order.unit}</div>
                  <div>{a.order.category}</div>
                  <div>Status: <span className={`position-static badge badge-${statusKey[a.status]}`}>{a.status.replace('_', ' ')}</span> </div>
                  <div>{a.rating ? <Rating rating={a.rating}/> : 'Not Rated'}</div>
                </div>
              </div>
            </li>
          })}
          </ul>
        </React.Fragment>}
        {(active === "withdrawn" || !active) && assignments.withdrawn && assignments.withdrawn.length >= 1 && <React.Fragment>
          <h3>Withdrawn</h3>
          <ul className="list-unstyled">
            {assignments.withdrawn && assignments.withdrawn.map(a => {
              return <li className="list-group-item" key={a.id}>
                <div className="d-flex justify-content-between">
                  <div className="w-50">
                    <div><b>{a.order.tenant}</b></div>
                    <div>Received {moment.utc(a.order.submitted).local().format("YYYY-MM-DD")}</div>
                    <div>Assigned {moment.utc(a.inserted_at).local().format("YYYY-MM-DD")}</div>
                    <div>Withdrawn {moment.utc(a.updated_at).local().format("YYYY-MM-DD")}</div>
                  </div>
                  <div className="w-50">
                    <div>{a.order.property} Unit {a.order.unit}</div>
                    <div>{a.order.category}</div>
                    <div>Status: <span className={`position-static badge badge-${statusKey[a.status]}`}>{a.status.replace('_', ' ')}</span> </div>
                    <div>{a.rating ? <Rating rating={a.rating}/> : 'Not Rated'}</div>
                  </div>
                </div>
              </li>
            })}
          </ul>
        </React.Fragment>}
        {(active === "revoked" || !active) && assignments.revoked && assignments.revoked.length >= 1 && <React.Fragment>
          <h3>Revoked</h3>
          <ul className="list-unstyled">
            {assignments.revoked && assignments.revoked.map(a => {
              return <li className="list-group-item" key={a.id}>
                <div className="d-flex justify-content-between">
                  <div className="w-50">
                    <div><b>{a.order.tenant}</b></div>
                    <div>Received {moment.utc(a.order.submitted).local().format("YYYY-MM-DD")}</div>
                    <div>Assigned {moment.utc(a.inserted_at).local().format("YYYY-MM-DD")}</div>
                    <div>Revoked {moment.utc(a.updated_at).local().format("YYYY-MM-DD")}</div>
                  </div>
                  <div className="w-50">
                    <div>{a.order.property} Unit {a.order.unit}</div>
                    <div>{a.order.category}</div>
                    <div>Status: <span className={`position-static badge badge-${statusKey[a.status]}`}>{a.status.replace('_', ' ')}</span> </div>
                    <div>{a.rating ? <Rating rating={a.rating}/> : 'Not Rated'}</div>
                  </div>
                </div>
              </li>
            })}
          </ul>
        </React.Fragment>}
        {(active === "rejected" || !active) && assignments.rejected && assignments.rejected.length >= 1 && <React.Fragment>
          <h3>Rejected (Deprecated)</h3>
          <ul className="list-unstyled">
            {assignments.rejected && assignments.rejected.map(a => {
              return <li className="list-group-item" key={a.id}>
                <div className="d-flex justify-content-between">
                  <div className="w-50">
                    <div><b>{a.order.tenant}</b></div>
                    <div>Received {moment.utc(a.order.submitted).local().format("YYYY-MM-DD")}</div>
                    <div>Assigned {moment.utc(a.inserted_at).local().format("YYYY-MM-DD")}</div>
                    <div>Rejected {moment.utc(a.updated_at).local().format("YYYY-MM-DD")}</div>
                  </div>
                  <div className="w-50">
                    <div>{a.order.property} Unit {a.order.unit}</div>
                    <div>{a.order.category}</div>
                    <div>Status: <span className={`position-static badge badge-${statusKey[a.status]}`}>{a.status.replace('_', ' ')}</span> </div>
                    <div>{a.rating ? <Rating rating={a.rating}/> : 'Not Rated'}</div>
                  </div>
                </div>
              </li>
            })}
          </ul>
        </React.Fragment>}
      </Col>
    </Row>
  }
}

export default Assignments;