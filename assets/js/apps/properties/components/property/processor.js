import React from 'react';
import {Row, Col, Input, Button, Popover, PopoverHeader, PopoverBody} from 'reactstrap';
import CreatePayscape from "./createPayscape";
import Select from '../../../../components/select';
import actions from '../../actions';

const processors = {
  Authorize: ['API Key', 'Transaction Key', 'Public Key'],
  Payscape: ['Cert', 'Term ID', 'Account Num'],
  BlueMoon: ['Serial', 'User', 'Password', 'Property ID'],
  TenantSafe: ['UserId', 'Password', 'Product Type'],
  '': ['']
};

const types = {cc: 'Credit Card', ba: 'Bank Account', lease: 'Lease Management', screening: 'Tenant Screening'};

const linkFor = (name, login) => {
  const key = {
    Payscape: `https://epay.propay.com/login/?username=${login}`
  };

  return key[name] || '';
};

class Processor extends React.Component {
  state = {processor: {property_id: this.props.propertyId, keys: [], name: '', ...this.props.processor}};

  change({target: {name, value}}) {
    this.setState({processor: {...this.state.processor, [name]: value}});
  }

  static getDerivedStateFromProps(props, state) {
    if (state.processor.property_id !== props.propertyId) {
      return {...state, processor: {property_id: props.propertyId, keys: [], name: '', ...props.processor}};
    }
    return null;
  }

  changeKey(index, {target: {value}}) {
    const {keys} = this.state.processor;
    keys[index] = value;
    this.setState({processor: {...this.state.processor, keys}});
  }

  toggleEdit() {
    if (this.state.editMode) {
      const {type} = this.props;
      actions.saveProcessor({...this.state.processor, type});
    }
    this.setState({editMode: !this.state.editMode});
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

  render() {
    const {processor: {keys, name, login, password}, editMode, propertyIds, createPayscape} = this.state;
    const {type, propertyId} = this.props;
    return <div>
      <Row className="mb-3">
        <Col>
          <h3 className="text-center">
            {types[type]} Processor
            <Button color={editMode ? 'success' : 'info'} className="ml-4" onClick={this.toggleEdit.bind(this)}>
              {editMode ? 'Save' : 'Edit'}
            </Button>
            <a className="btn btn-success ml-2" href={linkFor(name, login)} target="_blank">Log In</a>
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
          </h3>
        </Col>
      </Row>
      <Row className="mb-3">
        <Col sm={3} className="d-flex align-items-center">
          <b>Processor</b>
        </Col>
        <Col sm={9}>
          {editMode && <div className="d-flex">
            <div className="flex-auto">
              <Select name="name" value={name} onChange={this.change.bind(this)}
                      options={Object.keys(processors).filter(p => p.length > 1).map(p => {
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
            {editMode && <Input name="name" value={keys[index] || ''} disabled={field === 'Property ID'}
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
      {createPayscape &&
      <CreatePayscape type={type} propertyId={propertyId} toggle={this.toggleCreatePayscape.bind(this)}/>}
    </div>
  }
}

export default Processor;