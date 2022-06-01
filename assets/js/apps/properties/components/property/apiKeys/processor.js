import React from 'react';
import {Row, Col, Input, Button, Popover, PopoverHeader, PopoverBody} from 'reactstrap';
import CreatePayscape from "./createPayscape";
import Select from '../../../../../components/select';
import actions from '../../../actions';
import {processors, integrationOptions, linkFor} from "./data";

class Processor extends React.Component {
  state = {
    processor: {property_id: this.props.propertyId, keys: [], name: '', ...this.props.processor},
    externalId: this.props.externalId
  };

  change({target: {name, value}}) {
    this.setState({processor: {...this.state.processor, [name]: value}});
  }

  static getDerivedStateFromProps(props, state) {
    if (props.processor && state.processor.id !== props.processor.id) {
      return {
        ...state, processor: {property_id: props.propertyId, keys: [], name: '', ...props.processor},
        externalId: props.externalId
      };
    }
    return null;
  }

  changeKey(index, {target: {value}}) {
    const {keys} = this.state.processor;
    const newKeys = [...keys];
    newKeys[index] = value;
    this.setState({processor: {...this.state.processor, keys: newKeys}});
  }

  toggleEdit() {
    if (this.state.editMode) {
      const {type} = this.props;
      actions.saveProcessor({...this.state.processor, type});
    }
    this.setState({editMode: !this.state.editMode});
  }

  cancel() {
    const defaults = {property_id: this.props.propertyId, keys: [], name: '', ...this.props.processor};
    this.setState({editMode: false, processor: defaults});
  }

  togglePropertyId() {
    const {propertyIds, processor} = this.state;
    if (propertyIds) {
      this.setState({propertyIds: null});
    } else {
      const {propertyId, type} = this.props;
      actions.saveProcessor({...processor, property_id: propertyId, type}).then(() => {
        actions.listBlueMoonPropertyIds(processor.id).then(r => {
          this.setState({propertyIds: r.data});
        });
      });
    }
  }

  selectPropertyId({target: {value}}) {
    const {processor} = this.state;
    processor.keys[3] = value;
    actions.saveProcessor(processor).then(() => {
      this.setState({propertyIds: null});
    });
  }

  toggleCreatePayscape() {
    this.setState({createPayscape: !this.state.createPayscape});
  }

  changeExternalId({target: {value}}) {
    this.setState({externalId: value});
  }

  saveExternalId() {
    actions.updateProperty(this.props.propertyId, {external_id: this.state.externalId}).then(() => {
      this.props.parent.propertyChanged({external_id: this.state.externalId})
    })
  }

  render() {
    const {processor, editMode, propertyIds, createPayscape, externalId} = this.state;
    const {id: processorId, keys, name, login, password} = processor;
    const {type, propertyId} = this.props;
    if (!processorId && !editMode) {
      return <h3 className="d-flex align-items-center">
        No integration configured <Button color="success" className="ml-3" onClick={this.toggleEdit.bind(this)}>
        Create Now
      </Button>
      </h3>
    }
    return <div>
      {type === 'management' && <Row className="mb-3">
        <Col sm={3} className="d-flex align-items-center nowrap">
          <b>External ID</b>
        </Col>
        <Col sm={7}>
          <Input name="external_id" value={externalId} onChange={this.changeExternalId.bind(this)}/>
        </Col>
        <Col sm={2}>
          <Button color="success" onClick={this.saveExternalId.bind(this)}>
            Save
          </Button>
        </Col>
      </Row>}
      <Row className="mb-3">
        <Col sm={3} className="d-flex align-items-center">
          <b>Provider</b>
        </Col>
        <Col sm={9}>
          {editMode && <div className="d-flex">
            <div className="flex-auto">
              <Select name="name" value={name} onChange={this.change.bind(this)}
                      options={integrationOptions[type].filter(p => p.length > 1).map(p => {
                        return {label: p, value: p};
                      })}/>
            </div>
            {name === 'Payscape' &&
            <div className="ml-2">
              <Button color="success" onClick={this.toggleCreatePayscape.bind(this)}>
                Create Account
              </Button>
            </div>}
          </div>}
          {!editMode && name}
        </Col>
      </Row>
      {processors[name].map((field, index) => {
        return <Row key={field} className="mb-3">
          <Col sm={3} className="d-flex align-items-center nowrap">
            <b>{field}</b>
          </Col>
          <Col sm={9}>
            {editMode && <Input name="name" value={keys[index] || ''}
                                disabled={field === 'Property ID'}
                                type={field === 'Interface' && name === 'Yardi' ? 'textarea' : 'text'}
                                rows={6}
                                onChange={this.changeKey.bind(this, index)}/>}
            {!editMode && '*******'}
          </Col>
        </Row>
      })}
      <Row className="mb-3">
        <Col sm={3} className="d-flex align-items-center nowrap">
          <b>Login</b>
        </Col>
        <Col sm={9}>
          <Input name="login" value={login || ''} disabled={!editMode} onChange={this.change.bind(this)}/>
        </Col>
      </Row>
      <Row className="mb-3">
        <Col sm={3} className="d-flex align-items-center nowrap">
          <b>Password</b>
        </Col>
        <Col sm={9}>
          <Input name="password" value={password || ''} disabled={!editMode} onChange={this.change.bind(this)}/>
        </Col>
      </Row>
      <Row className="mb-3">
        <Col>
          <Button color={editMode ? 'success' : 'info'} onClick={this.toggleEdit.bind(this)}>
            {editMode ? 'Save' : 'Edit'}
          </Button>
          {editMode && <Button color="danger" className="ml-2" onClick={this.cancel.bind(this)}>
            Cancel
          </Button>}
          <a className="btn btn-success ml-2" href={linkFor(name, login, keys)} target="_blank">Log In</a>
          {type === 'lease' && <>
            <Button color='info' className="ml-4"
                    disabled={keys.length < 3}
                    id="set-property-id"
                    onClick={this.togglePropertyId.bind(this)}>
              Set Property ID
            </Button>
            {propertyIds && <Popover target="set-property-id" isOpen={!!propertyIds} placement="bottom">
              <PopoverHeader>Select Property</PopoverHeader>
              <PopoverBody className="d-flex">
                <div style={{width: 350}}>
                  <Select onChange={this.selectPropertyId.bind(this)}
                          options={propertyIds.map(id => {
                            return {label: id.name, value: id.id};
                          })}/>
                </div>
              </PopoverBody>
            </Popover>}
          </>}
        </Col>
      </Row>
      {createPayscape &&
      <CreatePayscape type={type} propertyId={propertyId} toggle={this.toggleCreatePayscape.bind(this)}/>}
    </div>
  }
}

export default Processor;