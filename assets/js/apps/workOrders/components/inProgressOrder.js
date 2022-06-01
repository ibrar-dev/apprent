import React from 'react';
import {
  Row,
  Col,
  Popover,
  PopoverBody,
  PopoverHeader,
  InputGroup,
  InputGroupAddon,
  Input,
  Alert,
  Button,
  Card,
  CardBody,
  CardHeader,
  Nav,
  NavItem,
  NavLink,
  Badge
} from 'reactstrap';
import moment from 'moment';
import actions from '../actions';
import Notes from './notes';
import {connect} from "react-redux";
import {Link} from "react-router-dom";
import Parts from "./parts";
import Assignments from "./assignments";
import OutsourceModal from "./outsourceModal";
import canEdit from '../../../components/canEdit';
import Materials from "./materials";
import jsPDF from "jspdf";

class InProgressOrder extends React.Component {
  state = {notifyTime: '', moreOptions: false, activeTab: 'notes'}

  revoke() {
    if (!confirm('Revoke this assignment?')) return;
    const assignment = this.props.order.assignments.filter(a => a.status === 'in_progress')[0];
    actions.revokeAssignment(assignment.id).then(() => {
      alert("Assignment has been revoked");
      actions.openWorkOrder(this.props.order.id, 'workOrder');
    });
  }

  togglePopover() {
    this.setState({...this.state, notifyPopover: !this.state.notifyPopover});
  }

  changeTime(e) {
    e !== '' ? this.setState({...this.state, notifyTime: e.target.value, error: false}) : this.setState({
      ...this.state,
      error: true
    });
  }

  notifyTenant(assignment_id) {
    this.state.notifyTime.length >= 1 ? actions.notifyTenantOfArrival(assignment_id, this.state.notifyTime).then(this.setState({
      ...this.state,
      success: true,
      notifyTime: ''
    })) : this.setState({...this.state, error: true});
  }

  toggleMoreOptions() {
    this.setState({...this.state, moreOptions: !this.state.moreOptions});
  }

  changeTab(type) {
    this.setState({...this.state, activeTab: type});
  }

  markPriority() {
    // Almost all of the orders in the db have a priority of 0, but some have 1 or 2.
    // Until we know exactly where that is being set and why, 3 will be something that is prioritized
    const priority = this.props.order.priority === 3 ? 0 : 3;
    actions.updateWorkOrder(this.props.order.id, {priority: priority})
  }

  outsource() {
    this.setState({outsourcePopover: !this.state.outsourcePopover});
  }

  showUnit(){
      this.setState({...this.state, unit: !this.state.unit});
  }

  printOrder() {
    const notes = this.props.order.notes
    const parts = this.props.order.parts
    const order = this.props.order
    const assignments = this.props.order.assignments
    const noteColumns= ["Created By"," Note", "Time"];
    const ticketColumns = ["Ticket Number", "Received", "Pets", "Entry"];
    const partColumn = ["Part Name", "Time Requested", 'Status'];
    const assignmentColumn = ["Assigned to", "Assigned At", "Comment","Status", 'Completed At', 'Rating'];
    var notesArray = []
    var ticketArray = []
    var partsArray = []
    var assignmentsArray = []

    ticketArray.push([order.ticket, moment.utc(order.submitted).local().format("YYYY-MM-DD h:MM A"), order.has_pet.value ? 'Pet In Unit' : 'No Pet Reported', order.entry_allowed.value ? 'Entry Allowed' : 'Resident Must Be Home' ])
    for (var i = 0; i < notes.length; i++) {
      notesArray.push([notes[i].tenant || notes[i].admin , notes[i].text, moment.utc(notes[i].inserted_at).local().format("YYYY-MM-DD h:MM A")])
    }
    for (var i = 0; i < order.assignments.length; i++) {
      notesArray.push([order.assignments[i].tech, order.assignments[i].tech_comments, moment.utc(order.assignments[i].updated_at).local().format("YYYY-MM-DD h:MM A")])
    }
    for (var i = 0; i < parts.length; i++) {
      partsArray.push([parts[i].name,  moment.utc(parts[i].inserted_at).local().format("YYYY-MM-DD h:MM A") , parts[i].status])
    }

    const pdf = new jsPDF("p", "mm", "a4");
    const tenant = order.tenant ? order.tenant : "Unoccupied"
    const status = order.assignments.length === 0 || order.assignments[0].status === 'withdrawn' || order.assignments[0].status === 'revoked' || order.assignments[0].status === 'revoked'? 'Open' : order.assignments[0].status

    pdf.text(13, 7, 'Property:' + ' ' + order.property.name)
    pdf.text(13, 15, 'Unit:' + ' ' + order.unit)
    pdf.text(13, 23, 'Tenant:' + ' ' + tenant )
    pdf.text(13, 31, 'Category:'+ ' ' + order.category)
    pdf.text(13, 39, 'Status:'+ ' ' + status)

    pdf.autoTable({head: [ticketColumns], body: ticketArray, theme: 'grid', startY: 45, headStyles: {fillColor: [5, 55, 135]},didDrawPageContent: function(data) {
        pdf.text(headerString, 20, 20);
      }});
    pdf.autoTable({head: [noteColumns], body: notesArray, theme: 'grid', startY: pdf.previousAutoTable.finalY + 10, headStyles: {fillColor: [5, 55, 135]},columnStyles: {0: {cellWidth: 30}, 1: {cellWidth: 120}, 2: {cellWidth: 30}},didDrawPageContent: function(data) {
        pdf.text(headerString, 20, 20);
      }});
    if(partsArray.length > 0 ){
      pdf.autoTable({head: [partColumn], body: partsArray, theme: 'grid', startY: pdf.previousAutoTable.finalY + 10, headStyles: {fillColor: [5, 55, 135]},didDrawPageContent: function(data) {
          pdf.text(headerString, 20, 20);
        }})}
    if(assignmentsArray.length > 0){
      pdf.autoTable({head: [assignmentColumn], body: assignmentsArray, theme: 'grid', startY: pdf.previousAutoTable.finalY + 10, headStyles: {fillColor: [5, 55, 135]},didDrawPageContent: function(data) {
          pdf.text(headerString, 20, 20);
        }});
    }
    pdf.save("WorkOrders.pdf");
  }

  render() {
    const {order, canManage} = this.props;
    const {notifyPopover, notifyTime, error, success, moreOptions, activeTab, outsourcePopover, unit} = this.state;
    const assignment = order.assignments.filter(a => a.status === 'in_progress')[0];
    return <Card>
      <CardHeader className="d-flex justify-content-between">
        <Link to="/orders" className="btn btn-danger btn-sm m-0">
          <i className="fas fa-arrow-left"/> Back
        </Link>
        <h3 className="mb-0">{order.property.name} {order.unit}: {order.tenant}
          {order.unit && <Button id="unit" color="link" size= "sm" onClick={this.showUnit.bind(this)}>Unit Info</Button>}
        </h3>
        {order.unit && <Popover placement="right" isOpen={unit} target="unit" toggle={this.showUnit.bind(this)}>
            <PopoverHeader>Unit Details</PopoverHeader>
            <PopoverBody>
                Floor Plan: {order.unit_floor_plan ? order.unit_floor_plan : "N/A"} <br/>
                Area: {order.unit_area ? order.unit_area : "N/A"} <br/>
                Status: {order.unit_status ? order.unit_status : "N/A"} <br/>
            </PopoverBody>
        </Popover>}
        <div />
      </CardHeader>
      <CardBody className={`border p-2 ${order.priority === 3 ? 'alert-danger' : ''}`}>
        <Row>
          <Col sm={6}>
            <h5>Ticket: #{order.ticket}</h5>
            <h5>Received: {moment.utc(order.submitted).local().format("YYYY-MM-DD h:MM A")}</h5>
            <div>{order.has_pet && 'Has Pet'}</div>
            <div>{order.entry_allowed && 'Entry Allowed'}</div>
            <h5>Assigned to <b>{assignment.tech} {moment.utc(assignment.confirmed_at).fromNow()}</b></h5>
            <h5>Assigned by <b>{assignment.admin}</b></h5>
            {canManage && <React.Fragment>
              <Button color="danger" className="mr-1" onClick={this.revoke.bind(this)}>Revoke</Button>
              <Button color='info'
                      className='ml-1'
                      id={`more-options-${order.id}`}
                      onClick={this.toggleMoreOptions.bind(this)}>
                Options
              </Button>
              <Button
                color='info'
                outline
                id={`edit-button-${order.id}`}
                className='ml-1'
                onClick={this.printOrder.bind(this)}>
                Print Order
              </Button>
              <Popover isOpen={moreOptions} target={`more-options-${order.id}`}>
                <PopoverHeader>More Options</PopoverHeader>
                <PopoverBody>
                  <Button outline block color='success' className="">Ping</Button>
                  <Button
                    outline
                    block
                    color={order.priority === 3 ? 'warning' : 'info'}
                    onClick={this.markPriority.bind(this)}>
                    {order.priority === 3 ? 'Unprioritize' : 'Prioritize'}
                  </Button>
                  <Button color='info'
                          block
                          outline
                          className=""
                          id={`notify-po-${order.id}`}
                          onClick={this.togglePopover.bind(this)}>
                    Notify
                  </Button>
                  <Popover isOpen={notifyPopover} target={`notify-po-${order.id}`} placement='right'
                           toggle={this.togglePopover.bind(this)}>
                    <PopoverHeader>Notify Tenant of Tech Arrival Time</PopoverHeader>
                    <PopoverBody>
                      <InputGroup>
                        <Input name='time'
                               value={notifyTime}
                               onChange={this.changeTime.bind(this)}/>
                        <InputGroupAddon addonType='prepend'>Minutes</InputGroupAddon>
                      </InputGroup>
                      {error &&
                      <Alert className='mt-1' color="danger">ETA cannot be blank</Alert>}
                      {success &&
                      <Alert className='mt-1' color="success">Email sent to tenant <i
                        className='fas fa-smile-o'/></Alert>}
                      <button
                        className={`btn btn-block btn-outline-${notifyTime.length >= 1 ? 'success' : 'warning disabled'} mt-1`}
                        onClick={this.notifyTenant.bind(this, assignment.id)}>
                        {notifyTime.length >= 1 ? 'Notify Tenant' : 'Please enter a time above'}
                      </button>
                    </PopoverBody>
                  </Popover>
                </PopoverBody>
              </Popover>
            </React.Fragment>}
          </Col>
          <Col sm={6}>
            <h5>{order.category}</h5>
            <div style={{maxHeight: '750px', overflowY: 'scroll'}}>
              <div>
                <Nav pills>
                  <NavItem>
                    <NavLink active={activeTab === 'notes'} onClick={this.changeTab.bind(this, 'notes')}>
                      <i className="fas fa-comments" />{' '}Notes
                    </NavLink>
                  </NavItem>
                  <NavItem>
                    {order.parts.length >= 1 && <NavLink active={activeTab === 'parts'} onClick={this.changeTab.bind(this, 'parts')}>
                      <i className="fas fa-cogs" />{' '}Parts <Badge pill color="danger">{order.parts.length}</Badge>
                    </NavLink>}
                  </NavItem>
                  <NavItem>
                    {order.no_access.length >= 1 && <NavLink active={activeTab === 'no_access'} onClick={this.changeTab.bind(this, 'no_access')}>
                      <i className="fas fa-ban" />{' '}Attempts
                    </NavLink>}
                  </NavItem>
                  {canEdit(["Super Admin", "Regional"]) && <NavItem>
                    {order.assignments.length >= 1 && <NavLink active={activeTab === 'assignments'} onClick={this.changeTab.bind(this, 'assignments')}>
                      <i className="fas fa-clipboard-list" />{' '}Assignments <Badge pill color="danger">{order.assignments.length}</Badge>
                    </NavLink>}
                  </NavItem>}
                  {canEdit(["Super Admin", "Tech"]) && <NavItem>
                    <NavLink active={activeTab === 'materials'} onClick={this.changeTab.bind(this, 'materials')}>
                      <i className="fas fa-toolbox" />{' '}Materials
                    </NavLink>
                  </NavItem>}
                </Nav>
              </div>
              <div style={{maxHeight: '750px', overflowY: 'scroll'}} className="mt-1 mb-1">
                {activeTab === 'notes' && <Notes orderId={order.id} notes={order.notes} assignments={order.assignments}/>}
                {activeTab === 'parts' && <Parts orderId={order.id} parts={order.parts} disableAdd={true} />}
                {activeTab === 'no_access' && <React.Fragment>
                  <ol>
                    {order.no_access.map((a, index) => (
                      <li key={index}>On <b>{moment.utc(a.time).local().format("YYYY-MM-DD h:MM A")}</b> {a.tech_name ? `${a.tech_name} made an attempt` : ""}</li>
                    ))}
                  </ol>
                </React.Fragment>}
                {activeTab === 'assignments' && <Assignments assignments={order.assignments} />}
                {activeTab === 'materials' && <Materials assignments={order.assignments} />}
              </div>
            </div>
          </Col>
        </Row>
      </CardBody>
      <OutsourceModal open={outsourcePopover} toggle={this.outsource.bind(this)} order={order}/>
    </Card>
  }
}

export default connect(({techs}) => {
  return {canManage: !!techs};
})(InProgressOrder);
