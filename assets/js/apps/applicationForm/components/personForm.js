import React from 'react';
import utils from './utils';
import actions from '../actions';
import {Row, Col} from 'reactstrap'

class PersonForm extends React.Component {

  editField(e) {
    actions.editCollection('occupants', this.props.index, e.target.name, e.target.value);
  }

  formatField(e) {
    actions.formatCollection('occupants', this.props.index, e.target.name, e.target.value);
  }

  render() {
    const {person, index, total, language} = this.props;
    const userField = utils.userField.bind(this, person);
    return <div className="person-form" style={{flex: `${100.0 / total}%`, minHeight: 395}}>
      {index === 0 && <div className="row margin-row">
        <div className="col-md-3">{language.status}</div>
        <div className="col-md-9">{person.status}</div>
      </div>}
      {index > 0 && userField('status', language.status, 'select', {options: ['Lease Holder', 'Occupant']})}
      <Row>
        <Col>
          {userField('full_name', language.full_name, 'full_name')}
        </Col>
        <Col>
          {userField('dob', language.dob, 'date', {openTo: -17, max: '0'})}
        </Col>
      </Row>
      <Row>
        <Col>
          {userField('email', language.email)}
        </Col>
        <Col>
          {userField('ssn', language.ssn, 'ssn')}
        </Col>
      </Row>
      <Row>
        <Col>
          {userField('home_phone', language.home_phone, 'phone')}
        </Col>
        <Col>
          {userField('work_phone', language.work_phone, 'phone')}
        </Col>
      </Row>
      <Row>
        <Col xs="6">
          {userField('cell_phone', language.cell_phone, 'phone')}
        </Col>
      </Row>
      <h4 style={{marginTop: 30}}>{language.drivers_license}</h4>
      <Row>
        <Col>
          {userField('dl_number', language.number)}
        </Col>
        <Col>
          {userField('dl_state', language.state, 'state')}
        </Col>
      </Row>
    </div>;
  }
}

// export default connect(({language}) => {
//   return {language}
// })(PersonForm)

export default PersonForm;