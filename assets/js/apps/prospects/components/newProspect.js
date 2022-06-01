import React from 'react';
import {connect} from 'react-redux';
import {Row, Col, Modal, ModalHeader, ModalBody, Input, Button} from 'reactstrap';
import DatePicker from '../../../components/datePicker';
import actions from '../actions';

const row = (label, field, placeholder, prospect, change, date = false, required) => {
  return <Row className="my-2">
    <Col sm={4} className="d-flex align-items-center">
      {label}
    </Col>
    <Col sm={8}>
      {date ? <DatePicker value={prospect[field]} name={field} onChange={change} required={required}/> :
        <Input value={prospect[field] || ''} placeholder={placeholder || label} name={field} onChange={change} className={`is-${required}`}/>}
    </Col>
  </Row>;
};

class NewProspect extends React.Component {
  state = {prospect: {}};

  change({target: {name, value}}) {
    this.setState({...this.state, prospect: {...this.state.prospect, [name]: value}});
  }

  canSave() {
    const {prospect} = this.state;
    if (!prospect.name || !prospect.street || !prospect.city || !prospect.state || !prospect.zip || !prospect.move_in || !prospect.contact_type || !prospect.traffic_source_id || !prospect.phone || !prospect.email) {
      return false;
    } else {
      return true;
    }
  }

  save() {
    let address = {street: this.state.prospect.street, city: this.state.prospect.city, state: this.state.prospect.state, zip: this.state.prospect.zip}
    let prospect = this.state.prospect;
    prospect.address = address;
    actions.createProspect(prospect).then(this.props.toggle);
  }

  render() {
    const {prospect} = this.state;
    const {toggle, trafficSources} = this.props;
    const change = this.change.bind(this);
    return <Modal isOpen={true} toggle={toggle} size="lg">
      <ModalHeader toggle={toggle}>
        New Prospect
      </ModalHeader>
      <ModalBody>
        <Row>
          <Col sm={6}>
            {row("Name", "name", "", prospect, change, false, prospect.name ? "valid" : "invalid")}
            {row("Address", "street", "Street", prospect, change, false, prospect.street ? "valid" : "invalid")}
            {row("", "city", "City", prospect, change, false, prospect.city ? "valid" : "invalid")}
            {row("", "state", "State", prospect, change, false, prospect.state ? "valid" : "invalid")}
            {row("", "zip", "Zip", prospect, change, false, prospect.zip ? "valid" : "invalid")}
          </Col>
          <Col sm={6}>
            {/*<Row className="my-2">*/}
              {/*<Col sm={4} className="d-flex align-items-center">*/}
                {/*Agent*/}
              {/*</Col>*/}
              {/*<Col sm={8} className="react-datepicker-wrapper-full">*/}
                {/*Agents should be handled by the server, automatically assigning to the current_user*/}
                {/*<Input type="select"*/}
                       {/*name="admin_id"*/}
                       {/*value={prospect.admin_id}*/}
                       {/*onChange={this.change.bind(this)}>*/}
                  {/*<option/>*/}
                  {/*{agents.map(a => <option key={a.id} value={a.id}>{a.name}</option>)}*/}
                {/*</Input>*/}
              {/*</Col>*/}
            {/*</Row>*/}
            {/*{row("Contact Date", "contact_date", "", prospect, change, true, prospect.contact_date ? "valid" : "invalid")}*/}
            {row("Move In", "move_in", "", prospect, change, true, prospect.move_in ? "valid" : "invalid")}
            <Row className="my-2">
              <Col sm={4} className="d-flex align-items-center">
                Contact Type
              </Col>
              <Col sm={8} className="d-flex align-items-center">
                <Input value={prospect.contact_type}
                       type="select"
                       name="contact_type"
                       className={`is-${prospect.contact_type ? 'valid' : 'invalid'}`}
                       onChange={change}>
                  <option value={null} />
                  <option value="Phone">Phone</option>
                  <option value="Electronic">E-Mail</option>
                  <option value="Text">Text</option>
                  <option value="Walk-In">Walk In</option>
                </Input>
              </Col>
            </Row>
            <Row className="my-2">
              <Col sm={4} className="d-flex align-items-center">
                Traffic Source
              </Col>
              <Col sm={8}>
                <Input value={prospect.traffic_source_id}
                       className={`is-${prospect.traffic_source_id ? 'valid' : 'invalid'}`}
                       type="select"
                       name="traffic_source_id"
                       onChange={change}>
                  <option/>
                  {trafficSources.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
                </Input>
              </Col>
            </Row>
            {row("Phone", "phone", "", prospect, change, false, prospect.phone ? "valid" : "invalid")}
            {row("Email", "email","", prospect, change, false, prospect.email ? "valid" : "invalid")}
          </Col>
        </Row>
        <Row>
          <Col sm={{size: 10, offset: 1}}>
            <Input type="textarea"
                   rows={4}
                   placeholder="Notes"
                   name="notes"
                   value={prospect.notes}
                   onChange={this.change.bind(this)}/>
          </Col>
        </Row>
        <Row className="mt-3">
          <Col sm={{size: 6, offset: 3}}>
            <Button color="success" block={true} onClick={this.save.bind(this)} disabled={!this.canSave()}>
              Create
            </Button>
          </Col>
        </Row>
      </ModalBody>
    </Modal>;
  }
}

export default connect(({trafficSources}) => {
  return {trafficSources}
})(NewProspect);