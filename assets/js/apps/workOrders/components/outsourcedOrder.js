import React, {Component} from 'react';
import {Row, Col, Button, Popover, PopoverHeader, PopoverBody, Card, CardHeader, CardBody} from 'reactstrap';
import Notes from './notes';
import actions from '../actions';
import {Link} from "react-router-dom";
import DatePicker from "../../../components/datePicker";
import moment from "moment";
import Select from 'react-select';
import Checkbox from '../../../components/fancyCheck';
import canEdit from '../../../components/canEdit';
import confirmation from '../../../components/confirmationModal';
import {connect} from "react-redux";

class OutsourcedOrder extends Component {
  state = {
    scheduled: this.props.order.scheduled,
    hasPets: {value: this.props.order.has_pet, label: `${this.props.order.has_pet}`},
    pets: {value: this.props.order.has_pet, label: `${this.props.order.has_pet}`},
    entryAllowed: {value: this.props.order.entry_allowed, label: `${this.props.order.entry_allowed}`},
    entry: {value: this.props.order.entry_allowed, label: `${this.props.order.entry_allowed}`},
    category: {value: this.props.order.category, label: this.props.order.category},
    values: {
      value: this.props.vendorCategories.filter(x => x.name === this.props.order.category).id,
      label: this.props.order.category
    },
    priority: this.props.order.priority
  };

  change(e) {
    this.setState({...this.state, [e.target.name]: e.target.value})
  }

  changeScheduled(d) {
    if (d) {
      this.setState({...this.state, scheduled: d.format('YYYY-MM-DD')});
    } else {
      this.setState({...this.state, scheduled: ""});
    }
  }

  completeOrder(order) {
    let vendorOrder = order;
    vendorOrder.status = 'Completed';
    const promise = actions.updateVendorOrder(vendorOrder);
    promise.then(() => {
      this.props.history.goBack();
    })
  }

  update() {
    const o = this.props.order;
    o.scheduled = this.state.scheduled;
    actions.updateVendorOrder(o);
  }

  deleteWorkOrder() {
    confirmation("Are you sure you want to obliterate this order? This cannot be undone and it will really truly delete the order. As if it never happened. Tread lightly").then(() => {
      actions.deleteVendorOrder(this.props.order.id).then(window.location.replace("/orders"));
    })
  }

  popToggle(type) {
    type !== "saved" ? this.setState({
      ...this.state,
      editPopover: !this.state.editPopover,
      values: {value: this.props.order.category, label: this.props.order.category}
    })
      :
      this.setState({
        ...this.state,
        editPopover: false,
        category: this.state.values,
        pets: this.state.hasPets,
        entry: this.state.entryAllowed
      })
  }

  showEdit() {
    this.setState({...this.state, editPopover: !this.state.editPopover});
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
    this.setState({...this.state, values: e});
  }

  updateOrder() {
    const order = {
      id: this.props.order.id,
      has_pet: this.state.hasPets.value,
      entry_allowed: this.state.entryAllowed.value,
      category_id: this.state.values.value,
      priority: this.state.priority
    };
    actions.updateVendorOrder(order).then(this.popToggle("saved"));
  }

  updatePriority() {
    const priority = this.state.priority === 3 ? 1 : 3;
    this.setState({...this.state, priority: priority}, this.updateOrder.bind(this));
  }

  showUnit() {
    this.setState({...this.state, unit: !this.state.unit});
  }

  render() {
    const {order} = this.props;
    const {scheduled, editPopover, hasPets, category, entryAllowed, values, entry, pets, unit, priority} = this.state;
    const date = scheduled ? moment(scheduled) : null;
    return <Card className={this.props.order.priority === 3 ? 'alert-danger' : ''}>
      <CardHeader className="d-flex justify-content-between">
        <Link to="/orders" className="btn btn-danger btn-sm m-0">
          <i className="fas fa-arrow-left"/> Back
        </Link>
        <h3 className="mb-0">{order.property} {order.unit}: {order.tenant}
          {order.unit && <Button id="unit" color="link" size="sm" onClick={this.showUnit.bind(this)}>Unit Info</Button>}
        </h3>
        {order.unit && <Popover placement="right" isOpen={unit} target="unit" toggle={this.showUnit.bind(this)}>
          <PopoverHeader>Unit Details</PopoverHeader>
          <PopoverBody>
            Floor Plan: {order.unit_floor_plan ? order.unit_floor_plan : "N/A"} <br/>
            Area: {order.unit_area ? order.unit_area : "N/A"} <br/>
            Status: {order.unit_status ? order.unit_status : "N/A"} <br/>
          </PopoverBody>
        </Popover>}
        <div/>
      </CardHeader>
      <CardBody>
        <Row>
          <Col sm={6}>
            <h4>Vendor: <b>{order.vendor_name}</b> Email: <b>{order.vendor_email}</b></h4>
            <h5>Phone <b>{order.vendor_phone || 'Not Available'}</b> {' '} Address: <b>{order.vendor_address || 'Not Available'}</b>
            </h5>
            <h5>Received: {moment.utc(order.creation_date).local().format("YYYY-MM-DD")}</h5>
            <h5>Scheduled: <DatePicker value={date}
                onChange={this.changeScheduled.bind(this)}/>
            </h5>
            <div>{pets.value ? 'Pet In Unit' : 'No Pet Reported'}</div>
            <div>{entry.value ? 'Entry Allowed' : 'Resident Must Be Home'}</div>
            <div>Original Order Created by {order.created_by ? order.created_by : 'Unknown'}</div>
            {order.outsourcer && <div>Outsourced by: {order.outsourcer}</div>}

            {order.status !== 'Completed' && <div className="my-2">
              <Row>
                <Col>
                  <Button color='info'
                    block outline
                    id={`edit-button-${order.id}`}
                    onClick={this.showEdit.bind(this)}>
                    Edit
                  </Button>
                </Col>
                <Col>
                  <Button color='info'
                    block outline
                    onClick={this.updatePriority.bind(this)}>
                    {priority === 3 ? 'UnPrioritize' : 'Prioritize'}
                  </Button>
                </Col>
                <Col>
                  <Button block outline color="success" onClick={this.completeOrder.bind(this, order)}>
                    Mark Complete
                  </Button>
                </Col>
                <Col>
                  <Button block outline color="info" onClick={this.update.bind(this)}>
                    Save Info
                  </Button>
                </Col>
                {canEdit(["Super Admin"]) && <Col>
                  <Button block outline color="danger" onClick={this.deleteWorkOrder.bind(this)}>Delete</Button>
                </Col>}
              </Row>
              <Popover style={{width: "270px"}} isOpen={editPopover} target={`edit-button-${order.id}`}
                toggle={this.popToggle.bind(this, "cancel")}>
                <PopoverHeader>Edit Workorder</PopoverHeader>
                <PopoverBody>
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
                        options={this.props.vendorCategories.map(x => {
                          return {label: x.name, value: x.id}
                        })}
                        onChange={this.searchSets.bind(this)}
                      />
                    </Col>
                  </Row>
                  <Row>
                    <Col><Button color='danger' size="sm" onClick={this.popToggle.bind(this, "cancel")}>Cancel</Button></Col>
                    <Col><Button color='success' size="sm" onClick={this.updateOrder.bind(this)}>Save</Button></Col>
                  </Row>
                </PopoverBody>
              </Popover>
            </div>}
            {order.status === 'Completed' && <React.Fragment>
              <h5>Completed: <b>{moment.utc(order.updated_at).local().format("YYYY-MM-DD")}</b></h5>
            </React.Fragment>}
          </Col>
          <Col sm={6}>
            <h5>Category > {category.label}</h5>
            <div>
              {<Notes orderId={order.id} notes={order.notes} status={order.status} assignments={order.assignments}
                disableAdd={false} type={"vendor"}/>}
            </div>
          </Col>
        </Row>
      </CardBody>
    </Card>
  }
}

export default connect(({vendorCategories}) => {
  return {vendorCategories};
})(OutsourcedOrder);
