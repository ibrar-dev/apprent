import React, {Component} from 'react';
import {connect} from "react-redux";
import {Row, Col, Button, Card, CardBody, CardHeader, Input} from 'reactstrap';
import moment from 'moment';
import actions from '../../actions';
import Select from '../../../../components/select';
import canEdit from '../../../../components/canEdit';
import CreationModal from './creationModal';
import ShowRecurring from './showRecurring';

class RecurringLetters extends Component {
  state = {
    creationModal: false
  }

  componentWillMount() {
    const {property} = this.props;
    actions.fetchRecurringLetters(property.id);
    actions.fetchAdmins();
  }

  selectLetter({target: {value: letter}}) {
    this.setState({...this.state, selectedLetter: letter})
  }

  toggleCreation() {
    this.setState({...this.state, creationModal: !this.state.creationModal})
  }

  render() {
    const {recurringLetters, letters, admins, property} = this.props;
    const {selectedLetter, creationModal} = this.state;
    // console.log(recurringLetters);
    return <Row>
      <Col>
        <Row>
          <Col className="d-flex justify-content-between">
            <Select className="flex-fill"
                    value={selectedLetter}
                    options={recurringLetters.map(l => {
                      return {label: l.name, value: l}
                    })}
                    onChange={this.selectLetter.bind(this)}
                    placeholder="Select Scheduled Letter" />
            {canEdit(["Super Admin", "Regional"]) && <Button onClick={this.toggleCreation.bind(this)} outline color="success" className="ml-3"><i className="fas fa-plus" /></Button>}
            {creationModal && <CreationModal toggle={this.toggleCreation.bind(this)} />}
          </Col>
        </Row>
        {selectedLetter && <Row className="mt-3">
          <ShowRecurring selectedLetter={selectedLetter} admins={admins} letters={letters} property={property}/>
        </Row>}
      </Col>
    </Row>
  }
}

export default connect(({property, recurringLetters, admins, letters}) => {
  return {property, recurringLetters, admins, letters}
})(RecurringLetters)