import React from 'react';
import {Collapse, Card, CardHeader, CardBody, Row, Col, Button, Popover, Input, CardFooter, Badge} from 'reactstrap';
import moment from 'moment';
import canEdit from '../../../components/canEdit';
import EditProspect from './editProspect';
import Showing from './showing';
import actions from '../actions';

class Prospect extends React.Component {
  state = {memo: '', success: false};

  toggle() {
    this.setState({collapse: !this.state.collapse});
  }

  toggleEdit() {
    this.setState({...this.state, edit: !this.state.edit})
  }

  scheduleShowing() {
    this.setState({...this.state, showing: !this.state.showing})
  }

  deleteProspect() {
    if (confirm('Delete this prospect?')) {
      actions.deleteProspect(this.props.prospect);
    }
  }

  contactProspect(e) {
    e.stopPropagation();
    this.setState({...this.state, contactPopover: !this.state.contactPopover});
  }

  updateMemo(e) {
    this.setState({...this.state, memo: e.target.value});
  }

  clear() {
    this.setState({...this.state, successfulSave: false});
  }

  saveMemo() {
    const memo = {notes: this.state.memo, prospect_id: this.props.prospect.id};
    actions.saveMemo(memo).then(this.setState({...this.state, successfulSave: true, memo: ''}));
  }

  render() {
    const {prospect, contactModal, toggle} = this.props;
    const memos = prospect.memos;
    const {collapse, edit, showing, contactPopover, memo, successfulSave} = this.state;
    return <Card className="mb-0 rounded-0" style={{marginTop: -1}}>
      <CardHeader onClick={this.toggle.bind(this)}
                  className="d-flex justify-content-between align-items-center clickable">
        <div><b>{prospect.name}</b>
          {memos[0] &&
          <span className='ml-5'>Last Contacted: {moment.utc(memos[0].contact_date).local().format("YYYY-MM-DD")} <Badge
            color='success'>{memos.length}</Badge></span>}
        </div>
        <Button id={`contact-popover-${prospect.id}`} color="info" className="m-0"
                onClick={toggle} size="sm">
          <i className="fas fa-envelope"/> Contact Prospect
        </Button>
      </CardHeader>
      <Collapse isOpen={collapse}>
        <CardBody>
          {!edit &&
          <div>
            <Row>
              <Col>
                <ul className="list-unstyled">
                  <li>
                    <b>Address:</b> {prospect.address.street} {prospect.address.city} {prospect.address.state}, {prospect.address.zip}
                  </li>
                  <li><b>Phone:</b> {prospect.phone}</li>
                  <li><b>Email:</b> {prospect.email}</li>
                  <li><b>Move In:</b> {prospect.move_in}</li>
                </ul>
              </Col>
              <Col>
                <ul className="list-unstyled">
                  <li><b>Agent:</b> {prospect.agent && prospect.agent.name}</li>
                  <li><b>Contact Date:</b> {prospect.contact_date}</li>
                  <li><b>Contact Type:</b> {prospect.contact_type}</li>
                  <li><b>Traffic Source:</b> {prospect.traffic_source && prospect.traffic_source.name}</li>
                </ul>
              </Col>
            </Row>
            <Row>
              <Col>
                <ul className="list-unstyled">
                  <li><b>Notes:</b> {prospect.notes}</li>
                </ul>
              </Col>
            </Row>
            {memos.length && <Row>
              <Col>
                <ul className="list-unstyled">
                  <li><b>Memos: </b></li>
                  {memos.map(m => {``
                    return <li
                      key={m.id}>On {moment.utc(m.contact_date).local().format("YYYY-MM-DD")}, <b>{m.admin}</b> recorded: <b>{m.notes}</b>
                    </li>
                  })}
                </ul>
              </Col>
            </Row>}
            {prospect.showings.length > 0 && <Row className="mb-2">
              <Col className="text-center">
                Showings scheduled for: {prospect.showings.map(s => moment(s.date).format('MM/DD/YYYY')).join(', ')}
              </Col>
            </Row>}
            <Row>
              <Col>
                <Button onClick={this.toggleEdit.bind(this)} block outline color="warning">Edit</Button>
              </Col>
              <Col>
                <Button onClick={this.scheduleShowing.bind(this)} block outline color="info">Schedule a Tour</Button>
              </Col>
              {canEdit(["Super Admin", "Regional"]) && <Col>
                <Button onClick={this.deleteProspect.bind(this)} block outline color="danger">Delete Prospect</Button>
              </Col>}
            </Row>
          </div>}
          {edit &&
          <EditProspect toggleEdit={this.toggleEdit.bind(this)} prospect={prospect}/>}
        </CardBody>
      </Collapse>
      {showing && <Showing prospect={prospect}
                           toggle={this.scheduleShowing.bind(this)}/>}
    </Card>;
  }
}

export default Prospect;
