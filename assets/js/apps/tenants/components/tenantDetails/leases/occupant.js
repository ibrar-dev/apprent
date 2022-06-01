import React from "react";
import confirmation from "../../../../../components/confirmationModal";
import actions from "../../../actions";
import {Button, Card, CardBody, CardFooter, Col, Input, Row} from "reactstrap";
import {Phone} from "../../../../../components/masked";

class Occupant extends React.Component {
  state = {edit: !this.props.occupant, occupant: this.props.occupant || {}};

  componentWillReceiveProps(nextProps, nextContext) {
    this.setState({edit: !nextProps.occupant, dirty: false, occupant: {...nextProps.occupant}});
  }

  change({target: {name, value}}) {
    const {occupant} = this.state;
    occupant[name] = value;
    this.setState({dirty: true, occupant})
  }

  edit() {
    this.setState({edit: !this.state.edit})
  }

  deletePerson() {
    confirmation('Delete this occupant?').then(() => {
      actions.deletePerson(this.state.occupant.id);
    });
  }

  save() {
    const {occupant} = this.state;
    const {tenantId, leaseId: lease_id} = this.props;
    confirmation('Please confirm you would like to save this occupant').then(() => {
      const func = occupant.id ? 'updateOccupant' : 'createOccupant';
      actions[func]({...occupant, lease_id}, tenantId).then(this.edit.bind(this));
    })
  }

  render() {
    const {edit, occupant} = this.state;
    const change = this.change.bind(this);
    return <Card>
      <CardBody>
        <Row>
          <Col>
            <div className="labeled-box form-group">
              <Input value={occupant.first_name || ''} disabled={!edit} name="first_name" onChange={change}/>
              <div className="labeled-box-label">First Name</div>
            </div>
            <div className="labeled-box form-group">
              <Input value={occupant.middle_name || ''} disabled={!edit} name="middle_name" onChange={change}/>
              <div className="labeled-box-label">Middle Name</div>
            </div>
            <div className="labeled-box form-group">
              <Input value={occupant.last_name || ''} name="last_name" disabled={!edit} onChange={change}/>
              <div className="labeled-box-label">Last Name</div>
            </div>
          </Col>
          <Col>
            <div className="labeled-box form-group">
              <Input value={occupant.email || ''} disabled={!edit} name="email" onChange={change}/>
              <div className="labeled-box-label">Email</div>
            </div>
            <div className="labeled-box form-group">
              <Phone value={occupant.phone || ''} disabled={!edit} name="phone" onChange={change}/>
              <div className="labeled-box-label">Phone</div>
            </div>
          </Col>
        </Row>
      </CardBody>
      <CardFooter className="d-flex justify-content-between">
        <Button color="warning" onClick={this.edit.bind(this)}>Edit</Button>
        <div className="d-inline-block">
          {occupant.id && <Button color="danger" className="mr-3" onClick={this.deletePerson.bind(this)}>Delete</Button>}
          <Button disabled={!edit} color="success" onClick={this.save.bind(this)}>Save</Button>
        </div>
      </CardFooter>
    </Card>;
  }
}

export default Occupant;