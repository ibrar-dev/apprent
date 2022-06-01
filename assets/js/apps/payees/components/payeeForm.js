import React from 'react';
import {withRouter} from "react-router-dom";
import {Card, CardHeader, CardBody, CardFooter, Button, Row, Col} from 'reactstrap';
import actions from '../actions';
import Select from '../../../components/select';
import {ValidatedInput} from '../../../components/validationFields';
import FancyCheck from '../../../components/fancyCheck';

const taxForms = ['None', '1099'];
const formField = (label, value, editMode, change, element, type) => {
  return <Col sm={6}>
    <div className="labeled-box form-view">
      <ValidatedInput context={this} className={!editMode ? "disabled-input" : ""}
                      validation={() => true} disabled={!editMode}
                      onChange={change} name={label.toLowerCase()} value={value || ''} type={type}/>
      <div className="labeled-box-label">{label.replace("_", " ")}</div>
    </div>
  </Col>;
};

class PayeeForm extends React.Component {
  state = {payee: this.props.payee, editMode: !this.props.payee.id};

  change({target: {name, value}}) {
    this.setState({...this.state, payee: {...this.state.payee, [name]: value}});
  }

  toggleEditMode() {
    this.setState({editMode: !this.state.editMode});
  }

  toggleCheck() {
    this.setState({
      payee: {...this.state.payee, consolidate_checks: !this.state.payee.consolidate_checks}
    })
  }

  save() {
    actions.savePayee(this.state.payee).then(this.toggleEditMode.bind(this));
  }

  render() {
    const {payee, editMode} = this.state;
    const {history} = this.props;
    const change = this.change.bind(this);
    return <Card>
      <CardHeader className="d-flex justify-content-between align-items-center">
        <h3 className="m-0">{payee.name}</h3>
        <Button size="sm" className="m-0"
                onClick={() => history.push("/payees")}
                color="danger">
          <i className="fas fa-arrow-circle-left"/> Back
        </Button>
      </CardHeader>
      <CardBody>
        <Row>
          <Col sm={9}>
            <Row className="mb-3">
              {formField('Name', payee.name, editMode, change)}
            </Row>
            <Row className="mb-3">
              {formField('Street', payee.street, editMode, change)}
              {formField('City', payee.city, editMode, change)}
            </Row>
            <Row className="mb-3">
              {formField('State', payee.state, editMode, change, <Select options={USSTATES} name="state"
                                                                         onChange={change}
                                                                         value={payee.state}/>)}
              {formField('Zip', payee.zip, editMode, change)}
            </Row>
            <Row className="mb-3">
              {formField('Phone', payee.phone, editMode, change)}
              {formField('Email', payee.email, editMode, change)}
            </Row>
            <Row className="mb-3">
              {formField('Tax_Form', payee.tax_form, editMode, change, <Select name="tax_form"
                                                                               onChange={change}
                                                                               value={payee.tax_form}
                                                                               options={taxForms.map(f => {
                                                                                 return {value: f, label: f}
                                                                               })}/>)}
              {formField('Tax_ID', payee.tax_id, editMode, change)}
            </Row>
          </Col>
          <Col sm={3} style={{borderLeft: "thin solid #e6e1e1"}}>
            <Row className="mb-3" style={{height: 34}}><Col>
              <div className="d-flex">
                <FancyCheck inline disabled={!editMode} checked={payee.consolidate_checks} label="Consolidated Check"
                            onChange={this.toggleCheck.bind(this)} style={{marginLeft: 12}}/>
              </div>
            </Col>
            </Row>
            {formField('Due_Period', payee.due_period, editMode, change, null, "number")}
          </Col>
        </Row>
      </CardBody>
      <CardFooter className="text-right">
        {editMode ?
          <Button color="success" onClick={this.save.bind(this)}>Save</Button> :
          <Button color="info" onClick={this.toggleEditMode.bind(this)}>Edit</Button>}
      </CardFooter>
    </Card>
  }
}

export default withRouter(PayeeForm);