import React from 'react';
import {connect} from 'react-redux';
import {Row, Col, Modal, ModalHeader, ModalBody, Input, Button} from 'reactstrap';
import {
  ValidatedDatePicker,
  ValidatedInput,
  ValidatedSelect,
  validate
} from '../../../../../components/validationFields';
import actions from '../../../actions';

const paymentTypes = [
  {label: 'Opening Balance', value: 'Opening Balance'},
  {label: 'Check', value: 'Check'},
  {label: 'Money Order', value: 'Money Order'}
];

class NewPayment extends React.Component {
  constructor(props) {
    super(props);
    const properties = {};
    props.tenant.leases.forEach(l => {
      properties[l.property.id] = l.property;
    });
    this.properties = Object.values(properties);
    this.state = {};
  }

  change({target: {name, value}}) {
    this.setState({...this.state, [name]: value});
  }

  changeAttachment({target: {files}}) {
    this.setState({...this.state, image: files[0]});
  }

  save() {
    validate(this).then(() => {
      const {tenant} = this.props;
      const params = {
        ...this.state,
        tenant_id: tenant.id,
        source: 'admin',
        property_id: tenant.leases[0].property.id,
        inserted_at: this.state.inserted_at.toISOString()
      };
      actions.createPayment(params).then(this.props.toggle);
    }).catch(() => {
    });
  }

  render() {
    const {toggle} = this.props;
    const {inserted_at, description, amount, transaction_id, property_id} = this.state;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>
        New Payment
      </ModalHeader>
      <ModalBody>
        <Row className="mb-3">
          <Col sm={3} className="d-flex align-items-center">
            Property
          </Col>
          <Col sm={9}>
            {this.properties.length === 1 ? this.properties[0].name :
              <ValidatedSelect context={this}
                               validation={(d) => !!d}
                               feedback="Select Property"
                               value={property_id}
                               name="property_id"
                               onChange={this.change.bind(this)}
                               options={this.properties.map(p => {
                                 return {
                                   label: p.name,
                                   value: p.id
                                 }
                               })}/>}
          </Col>
        </Row>
        <Row className="mb-3">
          <Col sm={3} className="d-flex align-items-center">
            Date
          </Col>
          <Col sm={9}>
            <ValidatedDatePicker context={this}
                                 validation={(d) => !!d}
                                 feedback="Please select a date"
                                 value={inserted_at}
                                 name="inserted_at"
                                 block={true}
                                 onChange={this.change.bind(this)}/>
          </Col>
        </Row>
        <Row className="mb-3">
          <Col sm={3} className="d-flex align-items-center">
            Description
          </Col>
          <Col sm={9}>
            <ValidatedSelect context={this}
                             validation={desc => !!desc}
                             feedback="Please select a description"
                             value={description}
                             name="description"
                             onChange={this.change.bind(this)}
                             options={paymentTypes}/>
          </Col>
        </Row>
        <Row className="mb-3">
          <Col sm={3} className="d-flex align-items-center">
            ID Number
          </Col>
          <Col sm={9}>
            <Input value={transaction_id || ''} name="transaction_id" onChange={this.change.bind(this)}/>
          </Col>
        </Row>
        <Row className="mb-3">
          <Col sm={3} className="d-flex align-items-center">
            Amount
          </Col>
          <Col sm={9}>
            <ValidatedInput context={this}
                            validation={(v) => v > 0}
                            feedback="Please enter amount"
                            type="number"
                            value={amount || ''}
                            name="amount"
                            onChange={this.change.bind(this)}/>
          </Col>
        </Row>
        <Row className="mb-3">
          <Col sm={3} className="d-flex align-items-center">
            Image
          </Col>
          <Col sm={9}>
            <Input type="file" onChange={this.changeAttachment.bind(this)}/>
          </Col>
        </Row>
        <div className="d-flex justify-content-center">
          <Button className="w-50" color="success" onClick={this.save.bind(this)}>
            Save
          </Button>
        </div>
      </ModalBody>
    </Modal>;
  }
}

export default connect(({tenant, accounts}) => {
  return {tenant, accounts};
})(NewPayment);