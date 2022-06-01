import React, {Fragment} from 'react';
import {
  Card, CardTitle, ListGroup, ListGroupItem,
  ListGroupItemText, ListGroupItemHeading, Badge, Button, Modal, ModalBody, ModalHeader, ModalFooter, Dropdown, DropdownToggle, DropdownMenu, DropdownItem, Input, Label, Form, FormGroup
} from 'reactstrap';
import moment from "moment";
import confirmation from '../../../../components/confirmationModal';
import actions from '../../actions';
import canEdit from '../../../../components/canEdit';
import {connect} from 'react-redux';




class ToolboxComponent extends React.Component {
  state = {
    modal: false,
    dropdownOpen: false,
    backdrop: true
  }

  toggle() {
    this.setState(prevState => ({
      modal: !prevState.modal
    }));
  }

  toggleDropDown() {
    this.setState(prevState => ({
      dropdownOpen: !prevState.dropdownOpen
    }));
  }


changeBackdrop(e) {
  let value = parseInt(e.target.value);
  this.setState({ backdrop: value });
}

returnToolboxItem(i) {
const id = i.id
const tech_id = i.tech_id
const stock_id = this.state.backdrop
  { Number.isInteger(this.state.backdrop) ? confirmation("Please confirm that this item has been returned to the shop selected.")
      .then(() => { this.setState({modal: false})
      actions.returnMaterial(id, tech_id, stock_id)}).then(() => this.setState({backdrop: true}))
    :
    confirmation("Please select a property")
  }
}

  render() {
    const { toolboxItems, properties, stocks} = this.props;
    return <Card body>
      <CardTitle>Items In Toolbox{" "}<Badge>{toolboxItems.length}</Badge></CardTitle>
      {toolboxItems.length >= 1 && <Fragment>
        <ListGroup>
          {toolboxItems.map(i => {
            return <ListGroupItem key={i.id}>
              <ListGroupItemHeading className="d-flex justify-content-between"><span>{i.material}</span><span>${i.cost / i.per_unit}</span></ListGroupItemHeading>
              <ListGroupItemText>
                {i.stock}
              </ListGroupItemText>
              <ListGroupItemText className="d-flex justify-content-between">
                <span>Added: {moment.utc(i.inserted_at).fromNow()} {i.admin ? `By ${i.admin}` : ''}</span><span>{canEdit(["Regional", "Super Admin"]) && <i className="fas fa-trash text-danger" onClick={this.toggle.bind(this, i)} />}</span>
              </ListGroupItemText>
              <Modal isOpen={this.state.modal} toggle={this.toggle.bind(this)}>
                <ModalHeader toggle={this.toggle.bind(this)}>Return Tool</ModalHeader>
                <ModalBody>
                  Please select the property that the item is being returned to.
                </ModalBody>
                <ModalFooter>
                  <FormGroup>
                    <Input type="select" name="backdrop" id="backdrop" onChange={this.changeBackdrop.bind(this)}>
                      <option >Select Shop</option>
                      {stocks.stocks.map(x => {
                      return <option data={x.name} value={x.id} key={x.id}>
                        {x.name}
                      </option>
                      })}
                    </Input>
                  </FormGroup>
                  <Button color="primary" onClick={this.returnToolboxItem.bind(this, i)}>Return Material</Button>{' '}
                </ModalFooter>
              </Modal>
            </ListGroupItem>
          })}
        </ListGroup>
      </Fragment>}
      {!toolboxItems.length && <h1>
        No Items Currently In Toolbox
      </h1>}
    </Card>
  }
}


export default connect(({properties, stocks}) => {
  return {properties, stocks};
})(ToolboxComponent)
