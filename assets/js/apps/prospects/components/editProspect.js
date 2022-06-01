import React, {Component} from 'react';
import {connect} from "react-redux";
import moment from "moment";
import {Row, Col, Button, Input} from 'reactstrap';
import actions from '../actions';
import DatePicker from '../../../components/datePicker';
import Select from '../../../components/select';
import Phone from '../../../components/masked/phone';

class EditProspect extends Component {
  state = {prospect: this.props.prospect};

  componentWillMount() {
    actions.fetchAgents();
  }

  updateProspect() {
    actions.updateProspect(this.state.prospect).then(this.props.toggleEdit);
  }

  change(e) {
    this.setState({...this.state, prospect: {...this.state.prospect, [e.target.name]: e.target.value}});
  }

  changeAddress({target: {name, value}}) {
    const {prospect} = this.state;
    const {address} = prospect;
    this.setState({...this.state, prospect: {...prospect, address: {...address, [name]: value}}});
  }

  changeDate(e) {
    const value = moment(e.target.value).format('YYYY-MM-DD');
    this.setState({...this.state, prospect: {...this.state.prospect, [e.target.name]: value}});
  }

  render() {
    const {prospect} = this.state;
    const {address} = prospect;
    const {agents, trafficSources} = this.props;
    return (
      <div>
        <Row>
          <Col>
            <ul className="list-unstyled">
              <li><b>Name:</b> <Input value={prospect.name} name="name" onChange={this.change.bind(this)}/></li>
              <li><b>Address:</b>
                <Row className="mb-2">
                  <Col sm={8} className="pr-0">
                    <Input value={address.street || ''} name="street" placeholder="Address" onChange={this.changeAddress.bind(this)}/>
                  </Col>
                  <Col sm={4}>
                    <Input value={address.city || ''} name="city" placeholder="City" onChange={this.changeAddress.bind(this)}/>
                  </Col>
                </Row>
                <Row>
                  <Col sm={8} className="pr-0">
                    <Select value={address.state || ''}
                            options={USSTATES}
                            name="state"
                            onChange={this.changeAddress.bind(this)}/>
                  </Col>
                  <Col sm={4}>
                    <Input value={address.zip || ''} name="zip" placeholder="ZIP" onChange={this.changeAddress.bind(this)}/>
                  </Col>
                </Row>
              </li>
              <li><b>Phone:</b> <Phone value={prospect.phone || ''} name="phone" onChange={this.change.bind(this)}/></li>
              <li><b>Email:</b> <Input value={prospect.email || ''} name="email" onChange={this.change.bind(this)}/></li>
            </ul>
          </Col>
          <Col>
            <ul className="list-unstyled">
              <li><b>Agent:</b></li>
              <li>
                <Input type="select"
                       name="admin_id"
                       value={(prospect.agent || {}).id}
                       onChange={this.change.bind(this)}>
                  <option/>
                  {agents.map(a => <option key={a.id} value={a.id}>{a.name}</option>)}
                </Input>
              </li>
              <li>
                <b>Contact Date:</b> <DatePicker value={prospect.contact_date}
                                                 name="contact_date"
                                                 onChange={this.changeDate.bind(this)}/>
              </li>
              <li>
                <b>Move In:</b> <DatePicker value={prospect.move_in}
                                            name="move_in"
                                            onChange={this.changeDate.bind(this)}/>
              </li>
              <li><b>Contact Type:</b> <Input value={prospect.contact_type} name="contact_type"
                                              onChange={this.change.bind(this)}/></li>
              <li><b>Traffic Source:</b></li>
              <li>
                <Input type="select"
                       name="traffic_source_id"
                       value={(prospect.traffic_source || {}).id}
                       onChange={this.change.bind(this)}>
                  <option/>
                  {trafficSources.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
                </Input>
              </li>
            </ul>
          </Col>
        </Row>
        <Row>
          <Col>
            <ul className="list-unstyled">
              <li><b>Notes:</b> <Input value={prospect.notes || ''}
                                       type="textarea"
                                       rows={4}
                                       name="notes"
                                       onChange={this.change.bind(this)}/></li>
            </ul>
          </Col>
        </Row>
        <Row>
          <Col>
            <Button onClick={this.props.toggleEdit} block outline color='danger'>Cancel</Button>
          </Col>
          <Col>
            <Button onClick={this.updateProspect.bind(this)} block outline color='success'>Save</Button>
          </Col>
        </Row>
      </div>
    )
  }
}

export default connect(({agents, trafficSources}) => {
  return {agents, trafficSources}
})(EditProspect);