import React, {Component} from 'react';
import {Row, Col, Modal, ModalHeader, ModalBody, ModalFooter, Button, Collapse, Alert} from 'reactstrap';
import Select from "../../../components/select";
import {connect} from "react-redux";
import actions from '../actions';
import {withRouter} from 'react-router';

const initialState = {
  selectedCategory: {},
  selectedVendor: {category_ids: []},
  showConfirm: false
};

class OutsourceModal extends Component {
  state = initialState;

  componentWillMount() {
    actions.fetchVendors();
    actions.fetchVendorCategories();
  }

  select(item, name) {
    this.setState({initialState, [name]: item, showConfirm: true});
  }

  change({target: {name, value}}) {
    this.setState({...this.state, [name]: value});
  }

  outSourceOrder() {
    const {category, selectedVendor} = this.state;
    actions.outsourceOrder({
      category_id: category,
      vendor_id: selectedVendor.id,
      order_id: this.props.order.id,
      status: 'Open',
      has_pet: this.props.order.has_pet,
      entry_allowed: this.props.order.entry_allowed,
      created_by: this.props.order.created_by
    }).then(r => {
      this.setState({...this.state, success: true});
      setTimeout(() => {
        this.props.history.push('/orders', {});
      }, 1500);
      actions.fetchOrders();
    }).catch((e) => {
      this.setState({...this.state, error2: true})
    });
  }

  render() {
    const {vendorCategories, vendors, open, toggle, order} = this.props;
    const {selectedVendor, selectedCategory, showConfirm, success, error2, category} = this.state;
    const propertyVendors = vendors.filter(v => v.category_ids.includes(category) && v.property_ids.includes(order.property.id));
    const propertyCategories = vendors.filter(v => v.property_ids.includes(order.property.id)).reduce((acc, cur) => {return acc.concat(cur.category_ids)}, []);

    return <Modal isOpen={open} placement='right' toggle={toggle} size='lg'>
      <ModalHeader toggle={toggle}>Send Service Request to Vendor</ModalHeader>
      <ModalBody>
        {(!success && !error2) && <Col style={{marginBottom: 20}}>
          <Row style={{marginBottom: 10}}>
            <Col sm={4}>
              <h4>Category</h4>
            </Col>
            <Col sm={8}>
              <Select value={category} placeholder="category" name="category"
                onChange={this.change.bind(this)}
                options={ vendorCategories.filter(x => propertyCategories.includes(x.id)).map(c => {
                  return {value: c.id, label: c.name}
                })}/>
            </Col>
          </Row>
          <Col>
            <Row>
              {propertyVendors.map(v => <Col sm={4} key={v.id}>
                <Button block className={`${selectedVendor === v ? 'active' : ''}`}
                  style={{marginBottom: 10, marginTop: 10}} outline color='info'
                  onClick={this.select.bind(this, v, "selectedVendor")} >
                  {v.name}
                </Button>
              </Col>
              )}
            </Row>
          </Col>
        </Col>}
        <Collapse isOpen={success}>
          <Alert color="success">
            Order Outsourced Successfully!
          </Alert>
        </Collapse>
        <Collapse isOpen={error2}>
          <h1> Order Outsource Unsuccessful </h1>
        </Collapse>
      </ModalBody>
      <Collapse isOpen={showConfirm && !success}>
        <ModalFooter>
          <h5 className='mr-auto'>Assign <strong>{order.unit}</strong>'s
            request, <strong>{order.category}</strong> to <strong>{selectedVendor.name}</strong></h5>
          <Button outline color='success' onClick={this.outSourceOrder.bind(this)}>Confirm</Button>
          <Button outline color='danger'>Cancel</Button>
        </ModalFooter>
      </Collapse>
    </Modal>
  }
}

export default withRouter(connect(({vendorCategories, vendors}) => {
  return {vendorCategories, vendors};
})(OutsourceModal));
