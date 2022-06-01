import React from 'react';
import {Input, Button, Row, Col} from 'reactstrap';
import Processor from './processor';
import actions from "../../actions";

class Credentials extends React.Component {
  state = {};

  toggleEditMode() {
    const {editMode} = this.state;
    if (editMode) actions.updateProperty({...this.props.property, ...this.state});
    this.setState({editMode: !this.state.editMode});
  }

  fieldFor(fieldName) {
    const {editMode} = this.state;
    const value = this.state[fieldName] || this.props.property[fieldName];
    if (editMode) {
      return (<Input value={value || ''}
                     className="ml-2 w-75"
                     placeholder={fieldName}
                     name={fieldName}
                     onChange={this.change.bind(this)}/>)
    }
    return value;
  }

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  render() {
    const {editMode} = this.state;
    const {property} = this.props;
    const {processors} = property;
    const processorKey = {};
    processors.forEach(p => processorKey[p.type] = p);
    return <div>
      <div className="d-flex align-items-center">
        <div className="mr-4 d-flex align-items-center">
          <div className="mr-4"><b className="mr-2">Code:</b> {this.fieldFor('code')}</div>
          <div className="mr-4"><b className="mr-2">External ID:</b> {this.fieldFor('external_id')}</div>
        </div>
        <Button className="btn-sm" color={editMode ? 'success' : 'info'} onClick={this.toggleEditMode.bind(this)}>
          {editMode ? 'Save' : 'Edit'}
        </Button>
      </div>
      <Row className="my-4">
        <Col sm={6}>
          <Processor propertyId={property.id} processor={processorKey.cc} type="cc"/>
        </Col>
        <Col sm={6}>
          <Processor propertyId={property.id} processor={processorKey.ba} type="ba"/>
        </Col>
      </Row>
      <Row className="mt-4">
        <Col sm={6}>
          <Processor propertyId={property.id} processor={processorKey.lease} type="lease"/>
        </Col>
        <Col sm={6}>
          <Processor propertyId={property.id} processor={processorKey.screening} type="screening"/>
        </Col>
      </Row>
    </div>
  }
}

export default Credentials;