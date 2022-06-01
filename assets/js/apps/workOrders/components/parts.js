import React, {Component, Fragment} from 'react';
import {Popover, PopoverHeader, PopoverBody, Button, Card, CardHeader, CardBody, ButtonGroup, Collapse, Input, ButtonDropdown} from 'reactstrap';
import moment from 'moment';
import actions from '../actions';
import confirmation from '../../../components/confirmationModal';

class Parts extends Component {
  state = {open: false, partName: ''}

  classToDisplay(status) {
    switch (status) {
      case "pending":
        return 'info';
      case "ordered":
        return 'info';
      case "delivered":
        return 'success';
      default:
        return 'warning'
    }
  }

  statusToDisplay(status) {
    switch (status) {
      case "pending":
        return "Ordered";
      case "ordered":
        return "Delivered";
      default:
        return "Pending";
    }
  }

  togglePopover(e) {
    e.stopPropagation();
    this.setState({...this.state, open: !this.state.open});
  }

  changePart(type, e) {
    this.setState({...this.state, [type]: e.target.value})
  }

  updatePart(id, status) {
    switch (status) {
      case "pending":
        return confirmation('Has the part been ordered? Please note that this will notify the resident that their part has been ordered').then(() => {
          actions.updatePart(id, this.props.orderId, {part: {status: 'ordered'}});
        });
      case "ordered":
        return confirmation('Has the part been received? Please note that this will notify the resident that the part has been received').then(() => {
          actions.updatePart(id, this.props.orderId, {part: {status: 'delivered'}});
        });
      default:
        return confirmation('Please confirm that you would like to change the status back to pending. This will notify the resident that their part was mistakenly marked as delivered.').then(() => {
          actions.updatePart(id, this.props.orderId, {part: {status: 'pending'}});
        });
    }
  }

  removePart(id) {
    confirmation('Are your sure you want to remove the part from this order? This will notify the resident that the part we have been waiting on has been canceled.').then(() => {
      actions.updatePart(id, this.props.orderId, {part: {status: "canceled"}});
    });
  }

  createPart() {
    const part = {order_id: this.props.orderId, name: this.state.partName};
    actions.createPart(part);
  }

  render() {
    const {parts, disableAdd} = this.props;
    const {openPartId, open, partName} = this.state;
    return <Fragment>
      {parts.map((part, index) => (
        <div key={part.id} className='d-flex'>
          <Button
            color={`outline-${this.classToDisplay(part.status)}`}
            disabled
            block
            className="mb-2 d-flex justify-content-between"
          >
            <span>{part.name} - {part.status}</span>
            <span>
              {part.status === "pending" ? moment.utc(part.inserted_at).local().format("MM-DD h:MM A") : moment.utc(part.updated_at).local().format("MM-DD h:MM A")}
            </span>
          </Button>
          <Button outline className="mb-2" onClick={this.updatePart.bind(this, part.id, part.status)}>
            {this.statusToDisplay(part.status)}
          </Button>
          <Button outline color="danger" className="mb-2" onClick={this.removePart.bind(this, part.id)}>
            <i className="fas fa-trash" />
          </Button>
        </div>
      ))}
      {!disableAdd && <Fragment>
        <Button outline
          block
          id="add-part-popover"
          onClick={this.togglePopover.bind(this)}
          color="success">
          Add Part
        </Button>
        <Popover target="add-part-popover"
          className="mw-100"
          toggle={this.togglePopover.bind(this)}
          isOpen={open}>
          <PopoverHeader>
            New Part
          </PopoverHeader>
          <PopoverBody>
            <Input className="form-control"
              value={partName}
              onChange={this.changePart.bind(this, 'partName')} />
          </PopoverBody>
          <Collapse isOpen={partName.length >= 2}>
            <Button outline
              color="success"
              onClick={this.createPart.bind(this)}
              block>
              Save
            </Button>
          </Collapse>
        </Popover>
      </Fragment>}
    </Fragment>
  }
}

export default Parts;
