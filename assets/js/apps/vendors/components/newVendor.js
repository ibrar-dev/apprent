import React from 'react';
import {connect} from 'react-redux';
import Select from '../../../components/select';
import CreatableSelect from 'react-select';
import {Modal, ModalHeader, ModalBody, Row, Col, Input, Button} from 'reactstrap';
import actions from '../actions';

const categoryOptions = (categories) => {
  return categories.map(r => {
    return {value: r.id, label: r.name};
  });
};

const propertyOptions = (properties) => {
    return properties.map(r => {
        return {value: r.id, label: r.name};
    });
};

const requiredStyles = {
    control: styles => ({ ...styles, borderColor:'#dc3545' })
};

class NewVendor extends React.Component {
  state = {
    name: '',
    email: '',
    address: '',
    phone: '',
    contact_name: '',
    category_ids: [],
    property_ids: [],
    categories: this.props.categories,
    properties: this.props.properties
  };


  change(e) {
    this.setState({...this.state, [e.target.name]: e.target.value});
  }

  changeRoles(newValue, actionMeta) {
      this.setState({...this.state, category_ids: newValue.map(x => {return x.value})})
  }

  changeProperties(newValue, actionMeta) {
    this.setState({...this.state, property_ids: newValue.map(x => {return x.value})})
  }

  submit() {
    actions.saveVendor(this.state).then(this.props.toggle);
  }

  reformatCategories(){
    return categoryOptions(this.props.categories).map(o => {
      return {value: o.label, label: o.label}
    })
  }

  reformatProperties(){
      return propertyOptions(this.props.properties).map(o => {
          return {value: o.label, label: o.label}
      })
  }

  render() {
    const {toggle} = this.props;
    const {name, email, address, phone, category_ids,property_ids, categories,properties,contact_name} = this.state;
    const change = this.change.bind(this);
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>
        New Vendor
      </ModalHeader>
      <ModalBody>
        <Row className="mb-2">
          <Col sm={3}>
            <b>Name</b>
          </Col>
          <Col sm={9}>
               <Input name="name"
                   value={name}
                   onChange={change}
                   invalid={name.length <= 1}/>
          </Col>
        </Row>
        <Row className="mb-2">
          <Col sm={3}>
            <b>Email</b>
          </Col>
          <Col sm={9}>
            <Input name="email"
                   value={email}
                   onChange={change}
                   invalid={email.length <= 1}/>
          </Col>
        </Row>
        <Row className="mb-2">
          <Col sm={3}>
            <b>Address</b>
          </Col>
          <Col sm={9}>
            <Input name="address" value={address} onChange={change}/>
          </Col>
        </Row>
        <Row className="mb-2">
          <Col sm={3}>
            <b>Phone</b>
          </Col>
          <Col sm={9}>
            <Input name="phone" value={phone} onChange={change}/>
          </Col>
        </Row>
        <Row className="mb-2">
            <Col sm={3}>
                <b>Contact Name</b>
            </Col>
            <Col sm={9}>
                <Input name="contact_name" value={contact_name} onChange={change}/>
            </Col>
        </Row>
        <Row className="mb-2">
            <Col sm={3}>
                <b>Properties</b>
            </Col>
            <Col sm={9}>
                <CreatableSelect
                    isMulti={true}
                    options={propertyOptions(properties)}
                    onChange={this.changeProperties.bind(this)}
                    styles ={property_ids.length == 0 && requiredStyles }/>

            </Col>
        </Row>
        <Row className="mb-2">
          <Col sm={3}>
            <b>Categories</b>
          </Col>
          <Col sm={9}>
            <CreatableSelect
                    isMulti={true}
                    options={categoryOptions(categories)}
                    onChange={this.changeRoles.bind(this)}
                    styles={category_ids.length == 0 && requiredStyles }/>
            
          </Col>
        </Row>
        <Button disabled={name.length <= 1 || email.length <= 1 || category_ids.length == 0 || property_ids.length == 0} onClick={this.submit.bind(this)} color="success">
          Submit
        </Button>
      </ModalBody>
    </Modal>;
  }
}

export default connect(({categories, properties}) => {
  return {categories, properties};
})(NewVendor);