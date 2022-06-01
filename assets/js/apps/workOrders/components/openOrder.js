import React from 'react';
import {connect} from 'react-redux';
import {Link} from 'react-router-dom';
import {Row, Col, Button, Popover, PopoverHeader, PopoverBody, Card, CardHeader, CardBody, Nav, NavItem, NavLink, Badge} from 'reactstrap';
import moment from "moment";
import Select from 'react-select';
import confirmation from "../../../components/confirmationModal";
import Checkbox from '../../../components/fancyCheck';
import {validate, ValidatedInput} from '../../../components/validationFields';
import OutsourceModal from './outsourceModal';
import actions from '../actions';
import Techs from './techs';
import Notes from './notes';
import Parts from './parts';
import Assignments from "./assignments";
import canEdit from '../../../components/canEdit';
import jsPDF from 'jspdf';

class OpenOrder extends React.Component {
  state = {
    selectedId: null,
    numPages: null,
    pageNumber: 1,
    selected: [],
    moreOptions: false,
    noteStatus: false,
    disabled: true,
    cancelReason: '',
    activeTab: 'notes',
    hasPets: {value: this.props.order.has_pet, label: `${this.props.order.has_pet}`},
    pets: {value: this.props.order.has_pet, label: `${this.props.order.has_pet}`},
    entryAllowed: {value: this.props.order.entry_allowed, label: `${this.props.order.entry_allowed}`},
    entry: {value: this.props.order.entry_allowed, label: `${this.props.order.entry_allowed}`},
    category: {
      value: {parent: this.props.order.category.split(" > ")[0]},
      label: this.props.order.category.split(" > ")[1]
    },
    values: {
      value: {parent: this.props.order.category.split(" > ")[0]},
      label: this.props.order.category.split(" > ")[1]
    },
    editPopover: false
  };

  onDocumentLoadSuccess = ({ numPages }) => {
    this.setState({ numPages });
  };


  availableTechs() {
    const {order, techs} = this.props;
    if (!techs) return null;
    if (!techs.length) return [];
    return techs.filter(t => {
      const isProperty = t.property_ids.includes(order.property.id);
      // const hasSkill = t.category_ids.includes(order.category_id);
      return isProperty && t.active;
    });
  }

  partsHold() {
    return this.props.order.parts.some(p => ["pending", "ordered"].includes(p.status));
  }

  deleteOrder() {
    validate(this).then(() => {
      confirmation('Cancelling this order will notify the tenant. \nThe reason mentioned here will be in the email. \nConfirm cancellation?').then(() => {
        const {order} = this.props;
        actions.deleteWorkOrder(order.id, this.state.cancelReason);
      });
    }).catch(() => {
    });
  }

  select(id) {
    const {selected} = this.state;
    const index = selected.indexOf(id);
    if (index === -1) {
      selected.push(id);
    } else {
      selected.splice(index, 1);
    }
    this.setState({...this.state, selectedId: id, selected});
  }

  showOutsource() {
    this.setState({...this.state, outsourcePopover: !this.state.outsourcePopover});
  }

  showEdit() {
    this.setState({...this.state, editPopover: !this.state.editPopover});
  }

  cancelPopover() {
    this.setState({...this.state, cancelPopover: !this.state.cancelPopover});
  }

  change({target: {name, value}}) {
    this.setState({...this.state, [name]: value});
  }

  changeTab(type) {
    this.setState({...this.state, activeTab: type});
  }

  handleChange(type) {
    type === 'pets' ? this.setState({
        ...this.state,
        hasPets: {value: !this.state.hasPets.value, label: `${!this.state.hasPets.value}`}
      }) :
      this.setState({
        ...this.state,
        entryAllowed: {value: !this.state.entryAllowed.value, label: `${!this.state.entryAllowed.value}`}
      })
  }

  searchSets(e) {
    this.setState({...this.state, category_id: e.id});
  }

  popToggle(type) {
    type !== "saved" ? this.setState({
        ...this.state,
        editPopover: !this.state.editPopover,
        values: {
          value: {parent: this.props.order.category.split(" > ")[0]},
          label: this.props.order.category.split(" > ")[1]
        }
      })
      :
      this.setState({
        ...this.state,
        editPopover: !this.state.editPopover,
        category: this.state.values,
        pets: this.state.hasPets,
        entry: this.state.entryAllowed
      })
  }

  updateOrder() {
    const order = {
      id: this.props.order.id,
      has_pet: this.state.hasPets.value,
      entry_allowed: this.state.entryAllowed.value,
      category_id: this.state.category_id
    };
    actions.updateWorkOrder(order.id, order);
  }

  markPriority() {
    // Almost all of the orders in the db have a priority of 0, but some have 1 or 2.
    // Until we know exactly where that is being set and why, 3 will be something that is prioritized
    const priority = this.props.order.priority === 3 ? 0 : 3;
    if (priority === 0 || confirm(" If you mark this work order as a priority all maintenance supervisors associated with this work order will be alerted. Do you want to proceed?")) {
      actions.updateWorkOrder(this.props.order.id, {priority: priority});
    }
  }

  showUnit(){
      this.setState({...this.state, unit: !this.state.unit});
  }

  componentDidMount(){
    this.setState({disabled: false})
  }

  printOrder() {
    const notes = this.props.order.notes
    const parts = this.props.order.parts
    const order = this.props.order
    const techs = this.availableTechs.bind(this)()
    const noteColumns= ["Created By"," Note", "Time"];
    const ticketColumns = ["Ticket Number", "Received", "Pets", "Entry"];
    const partColumn = ["Part Name", "Time Requested", 'Status'];
    const assignmentColumn = ["Assigned to", "Assigned At", "Status", 'Completed At', 'Rating'];
    var notesArray = []
    var ticketArray = []
    var partsArray = []
    var assignmentsArray = []
    ticketArray.push([order.ticket, moment.utc(order.submitted).local().format("YYYY-MM-DD h:mm A"), order.has_pet.value ? 'Pet In Unit' : 'No Pet Reported', order.entry_allowed.value ? 'Entry Allowed' : 'Resident Must Be Home' ])
    for (var i = 0; i < notes.length; i++) {
      notesArray.push([notes[i].tenant || notes[i].admin , notes[i].text, moment.utc(notes[i].inserted_at).local().format("YYYY-MM-DD h:MM A")])
    }
    for (var i = 0; i < order.assignments.length; i++) {
      notesArray.push([order.assignments[i].tech, order.assignments[i].tech_comments, moment.utc(order.assignments[i].updated_at).local().format("YYYY-MM-DD h:mm A")])
    }
    for (var i = 0; i < parts.length; i++) {
      partsArray.push([parts[i].name,  moment.utc(parts[i].inserted_at).local().format("YYYY-MM-DD h:mm A") , parts[i].status])
    }
    for (var i = 0; i < techs.length; i++) {
      const techName = techs[i].name
      for (var x = 0; x < techs[i].assignments.length; x++) {
        if(techs[i].assignments[x].order_id == order.id){
          assignmentsArray.push([techName || "",  moment.utc(assignments.inserted_at).local().format("YYYY-MM-DD h:mm A") || "", assignments.status|| "", assignments.completed_at|| "", assignments.rating|| ""])
        }
      }
    }
    const pdf = new jsPDF("p", "mm", "a4");
    const tenant = order.tenant ? order.tenant : "Unoccupied"
    const status = order.assignments.length === 0 || order.assignments[0].status === 'withdrawn' || order.assignments[0].status === 'revoked' || order.assignments[0].status === 'revoked'? 'Open' : order.assignments[0].status

    pdf.text(13, 7, 'Property:' + ' ' + order.property.name)
    pdf.text(13, 15, 'Unit:' + ' ' + order.unit)
    pdf.text(13, 23, 'Tenant:' + ' ' + tenant )
    pdf.text(13, 31, 'Category:'+ ' ' + order.category)
    pdf.text(13, 39, 'Status:'+ ' ' + status)

    pdf.autoTable({head: [ticketColumns], body: ticketArray, theme: 'grid', startY: 40, headStyles: {fillColor: [5, 55, 135]},didDrawPageContent: function(data) {
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
    const {selected, selectedId, outsourcePopover, cancelReason, cancelPopover, activeTab, editPopover, hasPets, entryAllowed, values, entry, pets, unit, disabled} = this.state;
    const callbacks = order.assignments.filter(a => a.status === 'callback');
    const techs = this.availableTechs();
    return <Card>
      <CardHeader className="d-flex justify-content-between align-items-center">
        <Link to="/orders" className="btn btn-danger btn-sm m-0" >
          <i className="fas fa-arrow-left"/> Back
        </Link>
        <h3 className={`mb-0 ${callbacks.length ? 'text-danger' : ''}`}>
          {order.property.name} {order.unit}: {order.tenant} {' '}
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
        <span>{' '}</span>
      </CardHeader>
      <CardBody className={`border p-2 ${order.priority === 3 ? 'alert-danger' : ''}`}>
        <div >
        <Row>
          <Col  sm={6} id='print'>
            <h5>Ticket: #{order.ticket}</h5>
            <div className="my-2">
              <Button color="danger" data-html2canvas-ignore
                      id={`cancel-order-${order.id}`}
                      outline
                      className={`${cancelPopover ? 'active' : null} mr-1`}
                      onClick={this.cancelPopover.bind(this)}>
                <i className="fas fa-trash"/>{' '}Cancel
              </Button>
              <Popover isOpen={cancelPopover} target={`cancel-order-${order.id}`} >
                <PopoverHeader>Enter Reason For Cancellation</PopoverHeader>
                <PopoverBody>
                  <ValidatedInput value={cancelReason}
                                  context={this}
                                  validation={(v) => v.length > 2}
                                  feedback="Reason is required"
                                  name='cancelReason'
                                  onChange={this.change.bind(this)}/>
                  <Button outline
                          block
                          color='danger'
                          className={`${cancelReason.length <= 3 ? 'disabled' : null} mt-1`}
                          onClick={this.deleteOrder.bind(this)} >
                    Confirm and Notify
                  </Button>
                </PopoverBody>
              </Popover>
              <Button data-html2canvas-ignore
                      outline
                      className="mr-1 ml-1"
                      color={order.priority === 3 ? 'warning' : 'info'}
                      onClick={this.markPriority.bind(this)}>
                {order.priority === 3 ? 'Unprioritize' : 'Prioritize'}
              </Button>
              <Button color='primary' data-html2canvas-ignore
                      outline
                      id={`edit-button-${order.id}`}
                      className='ml-1'
                      onClick={this.showEdit.bind(this)} >
                Edit
              </Button>
              <Button disabled={disabled} data-html2canvas-ignore
                      color='info'
                      outline
                      id={`edit-button-${order.id}`}
                      className='ml-1'
                      onClick={this.printOrder.bind(this)}>
                Print Order
              </Button>
              <Popover style={{width: "270px"}} isOpen={editPopover} target={`edit-button-${order.id}`}
                       toggle={this.popToggle.bind(this, "cancel")}>
                <PopoverHeader>Edit Workorder</PopoverHeader>
                <PopoverBody >
                  <Row>
                    <Col sm={4}>
                      Pets
                    </Col>
                    <Col sm={8}>
                      <Checkbox checked={hasPets.value} inline
                                onChange={this.handleChange.bind(this, "pets")} color={`primary`}/>
                    </Col>
                  </Row>
                  <Row>
                    <Col sm={4}>
                      Entry
                    </Col>
                    <Col sm={8}>
                      <Checkbox checked={entryAllowed.value} inline
                                onChange={this.handleChange.bind(this, "entry")} color={`primary`}/>
                    </Col>
                  </Row>
                  <Row>
                    <Col sm={4}>
                      Category
                    </Col>
                    <Col sm={8}>
                      <Select
                        defaultValue={values}
                        options={this.props.categories.map(x => {
                          return {
                            label: x.name, options: x.children.map(b => {
                              return {label: b.name, value: x.name, id: b.id }
                            })
                          }
                        })}
                        onChange={this.searchSets.bind(this)}
                      />
                    </Col>
                  </Row>
                  <Row>
                    <Col>
                      <Button color='danger' size="sm" onClick={this.popToggle.bind(this, "cancel")}>Cancel</Button>
                    </Col>
                    <Col><Button color='success' size="sm" onClick={this.updateOrder.bind(this)}>Save</Button></Col>
                  </Row>
                </PopoverBody>
              </Popover>
              <OutsourceModal open={outsourcePopover} toggle={this.showOutsource.bind(this)} order={order} />
            </div>
            <h5  >Received: {moment.utc(order.submitted).local().format("YYYY-MM-DD h:mm A")}</h5>
            <div >{pets.value ? 'Pet In Unit' : 'No Pet Reported'}</div>
            <div  >{entry.value ? 'Entry Allowed' : 'Resident Must Be Home'}</div>
            <div  >Alarm Code: {order.entryAllowed ? order.alarm_code : 'Not Authorized or Not Available'}</div>
            {order.assignments[0] && order.assignments[0].callback_info && <div>Callback by {order.assignments[0].callback_info.admin_name} on {moment.utc(order.assignments[0].callback_info.callback_time).local().format("YYYY-MM-DD h:MM A")}</div>}
            {order.assignments[0] && order.assignments[0].callback_info && <div style ={{width:" 400px"}}>Cause for callback: {order.assignments[0].callback_info.note} </div>}

          </Col>
          <Col sm={6} >
            <h5>{this.state.category.value.parent} > {this.state.category.label}</h5>
            <div>
              <Nav pills >
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
                {canEdit(["Super Admin", "Regional"]) && <NavItem>
                  {order.assignments && order.assignments.length >= 1 && <NavLink active={activeTab === 'assignments'} onClick={this.changeTab.bind(this, 'assignments')}>
                    <i className="fas fa-clipboard-list" />{' '}Assignments <Badge pill color="danger">{order.assignments.length}</Badge>
                  </NavLink>}
                </NavItem>}
              </Nav>
            </div>
            <div style={{maxHeight: '750px', overflowY: 'scroll'}} className="mt-1 mb-1"  >
              {activeTab === 'notes' && <Notes orderId={order.id} notes={order.notes} assignments={order.assignments}/>}
              {activeTab === 'parts' && <Parts orderId={order.id} parts={order.parts} note={this.state.noteStatus}/>}
              {activeTab === 'no_access' && <React.Fragment>
                <ol>
                  {order.no_access.map((a, index) => (
                    <li key={index}>On <b>{moment.utc(a.time).local().toString()}</b> {a.tech_name ? `${a.tech_name} made an attempt` : ""}</li>
                  ))}
                </ol>
              </React.Fragment>}
              {activeTab === 'assignments' && <Assignments assignments={order.assignments} />}
            </div>
          </Col>
        </Row>
          {techs && !this.partsHold() && <Techs
            orderId={order.id}
            offers={order.offers}
            callbacks={callbacks}
            property={order.property}
            techs={techs}
            select={this.select.bind(this)}
            selected={selected}
            selectedId={selectedId}/>}
      </div>
      </CardBody>
    </Card>;
  }
}

export default connect(({techs, vendors, categories}) => {
  return {techs, vendors, categories};
})(OpenOrder);
