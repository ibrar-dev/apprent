import React, {Component, Fragment} from 'react';
import {Row, Col, Input, Button} from 'reactstrap';
import {ChromePicker} from 'react-color';
import SocialButton from './socialButton';
import actions from "../../actions";
import states from "../../../../data/usStates";
import timeZones from "../../../../data/timeZones";
import Uploader from '../../../../components/uploader';

class Location extends Component {
  constructor(props) {
    super(props);
    this.state = {
      property: props.property,
      picker: false
    };
  }

  toggleEditMode() {
    const {property, editMode} = this.state;
    if (editMode) {
      actions.updateProperty(property);
    }
    this.setState({...this.state, editMode: !this.state.editMode});
  }

  fieldFor(fieldName, klassName) {
    const {property, editMode} = this.state;
    if (editMode) {
      return (
        <Input
          value={property[fieldName] || ''}
          className={klassName || "mb-2"}
          placeholder={fieldName}
          name={fieldName}
          onChange={this.change.bind(this)}
        />
      )
    }
    return property[fieldName];
  }

  timeZoneFieldFor(time_zone) {
    const {property, editMode} = this.state
    if (editMode) {
      const zones = timeZones.map(zone => <option key={zone} value={zone}>{zone}</option>)

      return (
        <Input
          type="select"
          value={property["time_zone"]}
          className="mb-2"
          name="time_zone"
          onChange={this.change.bind(this)}
        >
          {zones}
        </Input>
      )
    }
    return property["time_zone"]
  }

  static getDerivedStateFromProps(props, state){
    if(props.property.id !== state.property.id){
      return {...state, property: props.property};
    }else{
      return state;
    }
  }

  change({target: {name, value}}) {
    const {property} = this.state;
    property[name] = value;
    this.setState({property});
  }

  changeAddress({target: {name, value}}) {
    const {property} = this.state;
    property.address = {...property.address, [name]: value};
    this.setState({property});
  }

  addressFields(address) {
    if (this.state.editMode) {
      return <Fragment>
        <Row className="my-2">
          <Col sm={12}>
            <Input
              value={address.street}
              placeholder={'Address'}
              name="street"
              onChange={this.changeAddress.bind(this)}
            />
          </Col>
        </Row>
        <Row className="mb-2">
          <Col sm={5}>
            <Input
              value={address.city}
              placeholder={'City'}
              name="city"
              onChange={this.changeAddress.bind(this)}
            />
          </Col>
          <Col sm={3}>
            <Input
              type="select"
              name="state"
              value={address.state || ''}
              onChange={this.changeAddress.bind(this)}
            >
              {states.map((s) => (
                <option key={s.value} value={s.value}>{s.label}</option>
              ))}
            </Input>
          </Col>
          <Col sm={4}>
            <Input
              value={address.zip}
              placeholder={'ZIP'}
              name="zip"
              onChange={this.changeAddress.bind(this)}
            />
          </Col>
        </Row>
      </Fragment>;
    }
    return <div className="my-3">
      {`${address.street}`}
      <br/>
      {`${address.city} ${address.state} ${address.zip}`}
    </div>;
  }

  changeAttachment(field, att) {
    if (!att.filename) return;
    att.upload().then(() => {
      actions.updateProperty({id: this.props.property.id, [field]: {uuid: att.uuid}});
    });
  }

  togglePicker() {
    this.setState({picker: !this.state.picker})
  }

  updateColor(e) {
    let {property} = this.state;
    property.primary_color = e.hex;
    this.setState({property})
  }

  saveColor() {
    const {property} = this.state;
    actions.updateProperty(property).then(this.togglePicker.bind(this))
  }

  render() {
    const {property, editMode, picker} = this.state;
    return <Row>
      <Col sm={3}>
        <label>
          <b>Logo:</b>
          <div
            className="logo-thumbnail thumbnail-container mb-3"
            style={{minHeight: '100%'}}
          >
            <img
              className="img-thumbnail"
              src={property.logo || "/images/building.png"}
              alt="Logo"
            />
            <Uploader hidden onChange={this.changeAttachment.bind(this, 'logo')}/>
          </div>
        </label>
        <Row>
          <Col>
            <label>
              <b>Icon:</b>
              <div
                className="logo-thumbnail thumbnail-container mb-3"
                style={{minHeight: '100%'}}
              >
                <img
                  className="img-thumbnail"
                  src={property.icon || "/images/building.png"}
                  alt="Icon"
                />
                <Uploader modal hidden onChange={this.changeAttachment.bind(this, 'icon')}/>
              </div>
            </label>
          </Col>
          <Col>
            <label>
              <b>Banner:</b>
              <div
                className="logo-thumbnail thumbnail-container mb-3"
                style={{minHeight: '100%'}}
              >
                <img
                  className="img-thumbnail"
                  src={property.banner || "/images/building.png"}
                  alt="Banner"
                />
                <Uploader hidden onChange={this.changeAttachment.bind(this, 'banner')}/>
              </div>
            </label>
          </Col>
        </Row>
        <Row>
          <Col>
            {!picker &&
                <Button
                  outline
                  style={{color: property.primary_color}}
                  onClick={this.togglePicker.bind(this)}
                >
                  Primary Color
                </Button>
            }
            {picker && <div>
              <Button
                onClick={this.saveColor.bind(this)}
                outline
                color="success"
                className=""
              >
                Save
              </Button>
              <Button
                onClick={this.togglePicker.bind(this)}
                outline
                color="warning"
                className="ml-1"
              >
                Cancel
              </Button>
              <ChromePicker
                className="mt-1"
                color={property.primary_color}
                onChangeComplete={this.updateColor.bind(this)}
                disableAlpha={true}
              />
            </div>}
          </Col>
        </Row>
        <div className="btn-group pull-bottom mt-2 w-100">
        </div>
      </Col>
      <Col sm={9}>
        <div className="d-flex justify-content-between mb-3">
          <div className="d-flex align-items-center">
            Name: {this.fieldFor('name', 'mb-0 ml-2')}
          </div>
          <Button
            color={editMode ? 'success' : 'info'}
            onClick={this.toggleEditMode.bind(this)}
          >
            {editMode ? 'Save' : 'Edit'}
          </Button>
        </div>
        {property.address && this.addressFields(property.address)}
        <div className="mb-2">
          Website: {this.fieldFor('website')}
          {!editMode &&
              <a className={`ml-4 btn btn-outline-${property.website ? 'success' : 'warning disabled'}`}
                target='_blank'
                href={property.website}
              >
                Visit Website
              </a>
          }
        </div>
        <div>
          Phone: {this.fieldFor('phone')}
        </div>
        <div className="mt-1">
          Group Email: {this.fieldFor('group_email')}
        </div>
        <div className="mt-1">
          Time Zone: {this.timeZoneFieldFor(property.time_zone)}
        </div>
      </Col>
    </Row>
  }
}

export default Location;
