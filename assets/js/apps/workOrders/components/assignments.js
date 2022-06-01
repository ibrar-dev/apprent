import React, {Component} from 'react';
import {Card, CardHeader, CardBody, Button, Collapse, ListGroup, ListGroupItem, ListGroupItemHeading, Row, Col} from 'reactstrap';
import moment from 'moment';
import actions from '../actions';
import canEdit from '../../../components/canEdit';

// const ARRAY_OF_WORKING_ON = ["in_progress", "on_hold", "pending"]

class Assignments extends Component {
  state = {openAssignmentId: null}

  openAssignment(id, e) {
      e.stopPropagation();
      const openAssignmentId = this.state.openAssignmentId === id ? null : id;
      this.setState({...this.state, openAssignmentId});
  }

  checkIfProblemAssignments() {
    return this.props.assignments.filter(a => ARRAY_OF_WORKING_ON.includes(a.status)).length > 1;
  }

  deleteAssignment(assignment) {
    actions.deleteAssignment(assignment.id, assignment.order_id);
  }

  render() {
    const {assignments} = this.props;
    const {openAssignmentId} = this.state;
    return <div>
      {assignments.map(a => {
        return <div key={a.id}>
          <Button outline block color="success" onClick={this.openAssignment.bind(this, a.id || 0)}>{a.status}</Button>
          <Collapse isOpen={openAssignmentId === (a.id || 0)}>
            <Card>
              <CardHeader>
                <span>
                  Assigned to {a.tech} by {a.admin} on {moment.utc(a.confirmed_at).local().format("YYYY-MM-DD h:MM A")}
                </span>
              </CardHeader>
              <CardBody>
                <Row>
                  {a.history && <Col>
                    <ListGroup>
                      {a.history.map((h, index) => {
                        return (
                          <ListGroupItem key={index}>
                            {h.paused && <span>Paused: {moment.unix(h.paused).local().toString()}</span>}
                            {h.resumed && <span>Resumed: {moment.unix(h.resumed).local().toString()}</span>}
                          </ListGroupItem>
                        )
                      })}
                    </ListGroup>
                  </Col>}
                  <Col>
                    <ListGroup>
                      {a.tech_comments && <ListGroupItem>
                        <ListGroupItemHeading>{a.tech} Comment</ListGroupItemHeading>
                        {a.tech_comments || ""}
                      </ListGroupItem>}
                      <ListGroupItem>
                        <ListGroupItemHeading>Last Updated</ListGroupItemHeading>
                        {moment.utc(a.updated_at).local().toString()}
                      </ListGroupItem>
                      {a.callback_info && <ListGroupItem>
                        <ListGroupItemHeading>
                          Called Back on {moment.utc(a.callback_info.callback_time).local().toString} by {a.callback_info.admin_name}
                        </ListGroupItemHeading>
                        {a.callback_info.note}
                      </ListGroupItem>}
                      {canEdit(["Super Admin"]) && <ListGroupItem>
                        <Button block outline color="danger" onClick={this.deleteAssignment.bind(this, a)}><i className="fas fa-trash" /></Button>
                      </ListGroupItem>}
                    </ListGroup>
                  </Col>
                </Row>
              </CardBody>
            </Card>
          </Collapse>
        </div>
      })}
    </div>
  }
}

export default Assignments;
