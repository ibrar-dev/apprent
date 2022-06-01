import React from 'react';
import {Row, Col, Button, Card, CardBody, CardHeader, Modal,Input, ModalBody, ModalFooter,ModalHeader,Popover,PopoverHeader,PopoverBody, Nav, NavItem, NavLink, Badge} from 'reactstrap';
import moment from 'moment';
import actions from '../actions';
import Notes from './notes';
import {Link} from "react-router-dom";
import {withRouter} from 'react-router';
import confirmation from '../../../components/confirmationModal';
import canEdit from "../../../components/canEdit";
import Parts from './parts';
import jsPDF from "jspdf";


const colorOfStar = (rating) => {
  switch (rating) {
    case 1:
      return 'danger';
      break;
    case 2:
      return 'warning';
      break;
    case 3:
      return 'primary';
      break;
    case 4:
      return 'success';
      break;
    case 5:
      return 'success';
      break;
    default:
      return 'secondary';
      break;
  }
};

class CompletedOrder extends React.Component {
 state = {
     activeTab: 'notes',
      editRating: false,
      rating: ''
 }
  callbackOrder(){
    confirmation('Are you sure you want to re-open this completed order? \nDoing so will mark the order as a callback').then(() => {
      const assignment = this.props.order.assignments.filter(a => a.status === 'completed')[0];
      actions.callbackOrder(assignment,this.state.text);
    })
  }

  _daysAgo(){
    const assignment = this.props.order.assignments.filter(a => a.status === 'completed')[0];
    return moment().diff(assignment.completed_at, 'days');
  }

  toggleReOpen(){
    this.setState({reOpen: !this.state.reOpen});
  }

  handleNote(text){
    this.setState({text: text.target.value});
  }

  bugResident(assignment_id) {
   confirmation('Please confirm you would like to email the resident to remind them to rate this order').then(() => {
     actions.bugResident(assignment_id, this.props.order.id);
   });
  }

  shouldBeBugged() {
   const {order} = this.props;
   const assignment = order.assignments.filter(a => a.status === 'completed')[0];
   return moment(assignment.completed_at).isAfter(moment().subtract(7, 'days'));
  }

  changeTab(type) {
    this.setState({...this.state, activeTab: type});
  }

  showUnit(){
    this.setState({...this.state, unit: !this.state.unit});
  }

  editRating(){
    this.setState({...this.state, editRating: !this.state.editRating})
  }

  refreshWindow(){
    actions.openWorkOrder(this.props.order.id, 'workOrder');
    this.setState({...this.state, editRating: false})
  }

  ratingInput(event){
    this.setState({rating: event.target.value});
  }

  changeRating(id, rating) {
    confirmation(`Are you sure you would like to change this rating to ${rating} ?`).then(() => actions.editRating(id, rating)).then(() => this.refreshWindow())
  }

  hoverStar(value) {
   this.setState({...this.state, hoverStar: value})
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
    ticketArray.push([order.ticket, moment.utc(order.submitted).local().format("YYYY-MM-DD h:mm A"), order.has_pet.value ? 'Pet In Unit' : 'No Pet Reported', order.entry_allowed.value ? 'Entry Allowed' : 'Resident Must Be Home' ])
    for (var i = 0; i < notes.length; i++) {
      notesArray.push([notes[i].tenant || notes[i].admin , notes[i].text, moment.utc(notes[i].inserted_at).local().format("YYYY-MM-DD h:MM A")])
    }
    for (var i = 0; i < order.assignments.length; i++) {
      notesArray.push([order.assignments[i].tech, order.assignments[i].tech_comments, moment.utc(order.assignments[i].updated_at).local().format("YYYY-MM-DD h:MM A")])
    }
    for (var i = 0; i < parts.length; i++) {
      partsArray.push([parts[i].name,  moment.utc(parts[i].inserted_at).local().format("YYYY-MM-DD h:mm A") , parts[i].status])
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
    const {order} = this.props;
    const {reOpen, unit, activeTab, editRating, hoverStar} = this.state;
    const assignment = order.assignments.filter(a => a.status === 'completed')[0];
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
            <h5>Tech: {assignment.tech}</h5>
            <p>
              Received: {moment.utc(order.submitted).local().format("YYYY-MM-DD h:mm A")}
              <br/>
              Assigned: {moment.utc(assignment.confirmed_at).local().format("YYYY-MM-DD h:mm A")} by {assignment.admin}
              <br/>
              Completed: {moment.utc(assignment.completed_at).local().format("YYYY-MM-DD h:mm A")} by {assignment.tech}
            </p>
            <div>
              Comments from {assignment.tech}:
              <textarea className="form-control"
                        readOnly={true}
                        value={assignment.tech_comments || ''}
                        rows={5}/>
            </div>
            <div>Tenant Comment: {<div className="ml-2">{assignment.tenant_comment}</div> || "None"}</div>
            <div className="d-flex justify-content-between mt-2">
              <div>
                Tenant Rating: {
                  assignment.rating
                    ? [...Array(5)].map((n, index) => (
                    <i
                      key={index}
                      className={`fa mr-1 fa-2x fa-${index < assignment.rating ? 'star text-success' : 'star-o'}`}
                    />
                  ))
                  : 'Not rated'
                }
              </div>

              
            {!assignment.rating && order.tenant && (!assignment.email || assignment.email.length === 0) && this.shouldBeBugged() && <Button outline color="success" onClick={this.bugResident.bind(this, assignment.id)}>
              Bug Resident To Rate
            </Button>}
            {!assignment.rating && order.tenant && assignment.email && assignment.email.length >= 1 && <Button outline color="warning" disabled>
              Tenant was bugged by {assignment.email[assignment.email.length - 1].name}
              </Button>}
              {canEdit(["Super Admin"]) && assignment.rating && <Button outline color="success" onClick={this.editRating.bind(this)} >
                  Edit Rating
              </Button>}
              {editRating && <div style={{lineHeight: 1}}>
                <i style={{cursor: 'pointer'}} onClick={this.changeRating.bind(this, assignment.id, 1)} onMouseEnter={this.hoverStar.bind(this, 1)} onMouseLeave={this.hoverStar.bind(this, 0)} className={`fa${hoverStar >= 1 ? 's' : 'r'} fa-star fa-3x align-middle text-${colorOfStar(hoverStar)}`} />
                <i style={{cursor: 'pointer'}} onClick={this.changeRating.bind(this, assignment.id, 2)} onMouseEnter={this.hoverStar.bind(this, 2)} onMouseLeave={this.hoverStar.bind(this, 0)} className={`fa${hoverStar >= 2 ? 's' : 'r'} fa-star fa-3x align-middle text-${colorOfStar(hoverStar)}`} />
                <i style={{cursor: 'pointer'}} onClick={this.changeRating.bind(this, assignment.id, 3)} onMouseEnter={this.hoverStar.bind(this, 3)} onMouseLeave={this.hoverStar.bind(this, 0)} className={`fa${hoverStar >= 3 ? 's' : 'r'} fa-star fa-3x align-middle text-${colorOfStar(hoverStar)}`} />
                <i style={{cursor: 'pointer'}} onClick={this.changeRating.bind(this, assignment.id, 4)} onMouseEnter={this.hoverStar.bind(this, 4)} onMouseLeave={this.hoverStar.bind(this, 0)} className={`fa${hoverStar >= 4 ? 's' : 'r'} fa-star fa-3x align-middle text-${colorOfStar(hoverStar)}`} />
                <i style={{cursor: 'pointer'}} onClick={this.changeRating.bind(this, assignment.id, 5)} onMouseEnter={this.hoverStar.bind(this, 5)} onMouseLeave={this.hoverStar.bind(this, 0)} className={`fa${hoverStar >= 5 ? 's' : 'r'} fa-star fa-3x align-middle text-${colorOfStar(hoverStar)}`} />
              </div>}
              <Button
                color='info'
                outline
                id={`edit-button-${order.id}`}
                className='ml-1'
                onClick={this.printOrder.bind(this)}>
                Print Order
              </Button>
            </div>
          </Col>
          <Col sm={6}>
            <h5>{order.category}</h5>
              <div>
                  <Nav pills>
                      <NavItem>
                          <NavLink active={activeTab === 'notes'} onClick={this.changeTab.bind(this, 'notes')}>
                              <i className="fas fa-comments"/>{' '}Notes
                          </NavLink>
                      </NavItem>
                      <NavItem>
                          <NavLink active={activeTab === 'parts'} onClick={this.changeTab.bind(this, 'parts')}>
                              <i className="fas fa-cogs"/>{' '}Parts <Badge pill color="danger">{order.parts.length}</Badge>
                          </NavLink>
                      </NavItem>
                      <NavItem>
                          {order.no_access.length >= 1 && <NavLink active={activeTab === 'no_access'} onClick={this.changeTab.bind(this, 'no_access')}>
                              <i className="fas fa-ban"/>{' '}Attempts
                          </NavLink>}
                      </NavItem>
                      <NavItem>
                          <NavLink active={activeTab === 'materials'} onClick={this.changeTab.bind(this, 'materials')}>
                              <i className="fas fa-ban"/>{' '}Materials
                          </NavLink>
                      </NavItem>
                      {canEdit["Super Admin", "Regional"] && <NavItem>
                          {order.assignments.length >= 1 && <NavLink active={activeTab === 'assignments'} onClick={this.changeTab.bind(this, 'assignments')}>
                              <i className="fas fa-clipboard-list" />{' '}Assignments <Badge pill color="danger">{order.assignments.length}</Badge>
                          </NavLink>}
                      </NavItem>}
                  </Nav>
              </div>

              <div style={{maxHeight: '750px', overflowY: 'scroll'}} className="mt-1 mb-1">
                  {activeTab === 'notes' && <Notes orderId={order.id} notes={order.notes} assignments={order.assignments} disableAdd={false}/>}
                  {activeTab === 'parts' && <Parts orderId={order.id} parts={order.parts} disableAdd={true}/>}
                  {activeTab === 'no_access' && <React.Fragment>
                      <ol>
                          {order.no_access.map((a, index) => (
                              <li key={index}>On <b>{moment.utc(a.time).local().toString()}</b> {a.tech_name ? `${a.tech_name} made an attempt` : ""}</li>
                          ))}
                      </ol>
                  </React.Fragment>}
                  {activeTab === 'assignments' && <Assignments assignments={order.assignments} />}
                  {activeTab == 'materials' &&
                  <table className="table table-bordered">
                      <tbody>
                      {assignment.materials.map(m => {
                          return <tr key={m.name}>
                              <td>{m.num} X {m.name}</td>
                              <td>${m.cost.toFixed(2)}</td>
                              <td>${(m.cost * m.num).toFixed(2)}</td>
                          </tr>
                      })}
                      <tr>
                          <td colSpan={2} className="text-right">
                              <b>Total Cost:</b>
                          </td>
                          <td>
                              <b>${assignment.materials.reduce((sum, m) => sum + (m.cost * m.num), 0).toFixed(2)}</b>
                          </td>
                      </tr>
                      </tbody>
                  </table>}
              </div>
              <div>
                  {this._daysAgo() < 30 &&  <Button block
                                                    outline
                                                    color='warning'
                                                    onClick={this.toggleReOpen.bind(this)}>
                      Open Work Order
                  </Button>}
              </div>
          </Col>
        </Row>
          <Modal isOpen={reOpen} toggle={this.toggleReOpen.bind(this)} >
              <ModalHeader toggle={this.toggleReOpen.bind(this)}>Callback Note</ModalHeader>
              <ModalBody>
                  Please give a detailed reason as to why this order is being reopened.
                  <Input type="textarea" name="text" id="exampleText" onChange={this.handleNote.bind(this)}/>
              </ModalBody>
              <ModalFooter>
                  <Button color="primary" onClick={this.callbackOrder.bind(this)}>Callback</Button>{' '}
                  <Button color="secondary" onClick={this.toggleReOpen.bind(this)}>Cancel</Button>
              </ModalFooter>
          </Modal>
      </CardBody>
    </Card>
  }
}

export default withRouter((CompletedOrder));
