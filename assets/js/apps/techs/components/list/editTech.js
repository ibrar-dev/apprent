import React from 'react';
import {
  Row,
  Col,
  Card,
  CardBody,
  CardHeader,
  Button,
  Input,
  InputGroup,
  InputGroupAddon,
  InputGroupText,
  DropdownItem,
  Alert,
} from "reactstrap";
import actions from '../../actions';
import PropertySelect from './propertySelect';
import DropZone from '../../../../components/dropzone';
import Checkbox from '../../../../components/fancyCheck';
import confirmation from '../../../../components/confirmationModal';

class EditTech extends React.Component {
  state = {
    ...this.props.tech,
    invalidAttributes: false
  };

  change({target}) {
    this.setState({...this.state, [target.name]: target.value});
  }

  updateImage(file, name) {
    this.setState({...this.state, [name]: file})
  }

  changeCheckbox(name, value) {
    this.setState({...this.state, [name]: value})
  }

  disableTech() {
    const {active, id} = this.state;
    confirmation(`Please confirm that you would like to ${active ? 'disable' : 'enable'} this tech. \n${active ? 'Disabling will stop the tech from receiving new work orders but will not change any previous orders' : 'Enabling will mean they can receive work orders'}`).then(() => {
      const tech = {tech: {active: !active, single: true}}
      actions.updateTech(id, tech).then(this.props.toggle);
    })
  }

  updateTech() {
    const {name, phone_number, email, property_ids, image, id, can_edit, active, require_image} = this.state;
    if (name === '' || phone_number === '' || email === '' || property_ids === []) {
      this.setState({...this.state, invalidAttributes: true})
    } else {
      const tech = new FormData();
      tech.append('tech[name]', name);
      tech.append('tech[phone]', phone_number);
      tech.append('tech[email]', email);
      tech.append('tech[can_edit]', can_edit);
      tech.append('tech[require_image]', require_image);
      property_ids.length ? property_ids.forEach((item, index) => tech.append(`tech[property_ids][]`, item)) : tech.append(`tech[property_ids]`, "clear")
      this.props.tech.category_ids.forEach((item, index) => tech.append(`tech[category_ids][]`, item));
      if (image) tech.append('tech[image]', image);
      actions.updateTech(id, tech).then(this.props.toggle);
    }
  }

  onDismiss() {
    this.setState({...this.state, invalidAttributes: false});
  }

  addToPropertyIDs(id) {
    let propertyArray = this.state.property_ids;
    propertyArray.includes(id) ? propertyArray.splice(propertyArray.indexOf(id), 1) : propertyArray.push(id);
    this.setState({...this.state, property_ids: propertyArray});
  }

  addImage({target: {files}}) {
    const reader = new FileReader();
    reader.readAsDataURL(files[0]);
    reader.onload = () => {
      this.setState({...this.state, image: files[0], imageData: reader.result});
    };
  }

  render() {
    const {name, phone_number, email, type, invalidAttributes, imageData, can_edit, active, require_image} = this.state;
    const style = {
      border: '1px solid grey',
      borderRadius: '5px',
      maxHeight: '150px',
      overflowY: 'scroll'
    };
    return <Card>
      <CardHeader>
        <div className="w-50 d-inline-block pr-1">
          <Input name="name" value={name} onChange={this.change.bind(this)}/>
        </div>
        <div className="w-50 d-inline-block pl-1">
          <Input name="type" value={type} onChange={this.change.bind(this)}/>
        </div>
      </CardHeader>
      <CardBody>
        <Row>
          <Col md={7}>
            <Col md={12}>
              <InputGroup>
                <InputGroupAddon addonType="prepend">
                  <InputGroupText className="bg-info">
                    <i className="fas fa-phone text-white"/>
                  </InputGroupText>
                </InputGroupAddon>
                <Input name="phone_number" value={phone_number} onChange={this.change.bind(this)}/>
              </InputGroup>
            </Col>
            <br/>
            <Col md={12}>
              <InputGroup>
                <InputGroupAddon addonType="prepend">
                  <InputGroupText className="bg-info">
                    <i className="fas fa-envelope text-white"/>
                  </InputGroupText>
                </InputGroupAddon>
                <Input type="email" name="email" value={email} onChange={this.change.bind(this)}/>
              </InputGroup>
            </Col>
            <br/>
            <Col md={12}>
                <DropZone onChange={(file) => this.updateImage(file, "image")} />
            </Col>
            {invalidAttributes &&
            <Alert color="danger" toggle={this.onDismiss.bind(this)}>
              <p>Please make sure all the information is correct</p>
            </Alert>}
          </Col>
          <Col md={5}>
            <Col md={12} style={style}>
              {this.props.properties.map((p, index) => {
                return (<PropertySelect key={index} property={p} checked={this.addToPropertyIDs.bind(this)}
                                        property_ids={this.state.property_ids}/>)
              })}
            </Col>
            <Col md={12}>
              Allow Tech to edit their profile: <Checkbox checked={can_edit} name="can_edit" inline onChange={this.changeCheckbox.bind(this, "can_edit", !can_edit)}/>
            </Col>
            <Col md={12}>
              Require Images: <Checkbox checked={require_image} name="require_image" inline onChange={this.changeCheckbox.bind(this, "require_image", !require_image)}/>
            </Col>
          </Col>
        </Row>
        <Row>
          <Col md={12}>
            <Button className='mt-1' block outline color={active ? 'danger' : 'success'} onClick={this.disableTech.bind(this)}>{active ? 'Disable' : 'Enable'} Technician</Button>
          </Col>
        </Row>
        <DropdownItem divider/>
        <Button color="info" onClick={this.updateTech.bind(this)}>Update</Button>
        <Button className="float-right" color="warning" onClick={this.props.toggle}>Cancel</Button>
      </CardBody>
    </Card>
  }

}

export default EditTech;
