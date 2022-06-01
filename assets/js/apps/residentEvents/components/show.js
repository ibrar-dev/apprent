import React from 'react';
import {connect} from 'react-redux';
import moment from "moment";
import {Card, CardHeader, CardBody, CardTitle, Button, Row, Col, ListGroup, ListGroupItem, Input, Label, Badge} from 'reactstrap';
import actions from '../actions';
import canEdit from '../../../components/canEdit';
import icons from '../../../components/flatIcons';
import QrReader from 'react-qr-reader';

class ShowEvent extends React.Component {
  state = {
    tenant_id: null
  }

  back() {
    actions.showEvent(null)
  }

  toggleQr() {
    this.setState({...this.state, codeReader: !this.state.codeReader})
  }

  updateTenantID(e) {
    if (isNaN(e.target.value)) return;
    this.setState({...this.state, tenant_id: e.target.value})
  }

  handleScan(e) {
    if(e) this.setState({...this.state, tenant_id: e}, this.registerResident.bind(this))
  }

  handleError(error) {
    this.setState({...this.state, error: error});
  }

  registerResident() {
    const resident_event_attendance = {
      tenant_id: this.state.tenant_id,
      resident_event_id: this.props.showEvent.id
    }
    actions.registerResident(resident_event_attendance)
  }

  render() {
    const {showEvent} = this.props;
    const {codeReader, tenant_id} = this.state;
    return <Card>
      <CardHeader>
        {showEvent.name}
      </CardHeader>
      <CardBody className='d-flex flex-column'>
        <div className="top-bar">
          <Button onClick={this.back.bind(this)} size="sm" color="danger"><i className='fas fa-arrow-left' /></Button>
        </div>
        <Row className="mt-3">
          <Col>
            <Card body>
              <CardTitle>Sign In Residents</CardTitle>
              {!codeReader && <img onClick={this.toggleQr.bind(this)} src={icons.plus_ar} className="img-fluid" alt=""/>}
              {codeReader && <React.Fragment>
                {!canEdit(["Super Admin", "Regional"]) && <QrReader resolution={1200} onError={this.handleError.bind(this)} style={{width: 450, height: 450}} onScan={this.handleScan.bind(this)} />}
                <QrReader resolution={1200} onError={this.handleError.bind(this)} style={{width: 450, height: 450}} onScan={this.handleScan.bind(this)} />
                {canEdit(["Super Admin", "Regional"]) && <div className="form-group">
                  <Label>
                    Resident ID
                  </Label>
                  <Input value={tenant_id} onChange={this.updateTenantID.bind(this)} />
                  <Button outline color="success" onClick={this.registerResident.bind(this)}>Submit</Button>
                </div>}
              </React.Fragment>}
            </Card>
          </Col>
          {(canEdit(["Super Admin", "Regional"]) || moment().format("YYYY-MM-DD") === showEvent.date) && <Col>
            <Card body>
              <CardTitle className="d-flex justify-content-between"><span>Registered Residents</span><Badge pill color="success">{showEvent.attendees.length}</Badge></CardTitle>
              {showEvent.attendees.length && <ListGroup>
                {showEvent.attendees.map(a => {
                  return <ListGroupItem key={a.id}>{a.name}</ListGroupItem>
                })}
              </ListGroup>}
              {!showEvent.attendees.length && <h4>No Residents Yet</h4>}
            </Card>
          </Col>}
        </Row>
      </CardBody>
    </Card>
  }
}

export default connect(({showEvent}) => {
  return {showEvent}
})(ShowEvent)