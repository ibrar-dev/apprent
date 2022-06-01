import React from 'react';
import {Collapse, Button, CardBody, Card, Badge, Row, Col, Input} from 'reactstrap';
import {titleize} from "../../../../utils";
import actions from '../../actions';
import {ValidatedInput, validate} from "../../../../components/validationFields";
import snackbar from "../../../../components/snackbar";

class Integration extends React.Component {
  state = {set: {...this.props.set}};

  toggleOpen() {
    this.setState({isOpen: !this.state.isOpen})
  }

  changeCred(field, {target: {value}}) {
    const {set} = this.state;
    const credentials = [...set.credentials].filter(c => c.name !== field);
    credentials.push({name: field, value});
    const newSet = {...set, credentials}
    this.setState({set: newSet})
  }

  save() {
    validate(this).then(() => {
      const {set} = this.state;
      const func = set.id ? 'updateCredentialSet' : 'createCredentialSet';
      actions[func](set).then(() => {
        snackbar({
          message: "Credentials Saved",
          args: {type: 'success'}
        });
      })
    })
  }

  render() {
    const {integration} = this.props;
    const {isOpen, set} = this.state;
    return <div>
      <Card>
        <CardBody>
          <div className="d-flex justify-content-between align-items-center">
            <h3 className="m-0">{integration.provider}</h3>
            {!set.id && <h3 className="m-0"><Badge color="danger">Not Set</Badge></h3>}
            <Button color="primary" onClick={this.toggleOpen.bind(this)}>View</Button>
          </div>
          <Collapse isOpen={isOpen}>
            <div className="mt-4">
              {integration.fields.map((field) => {
                const credential = set.credentials.find(c => c.name === field)
                return <Row className="mb-2" key={field}>
                  <Col sm={3} className="d-flex align-items-center text-bold">
                    {titleize(field)}
                  </Col>
                  <Col sm={9}>
                    <ValidatedInput context={this}
                                    validation={r => !!r}
                                    feedback="Required Field"
                                    name={field}
                                    value={credential ? credential.value : ''}
                                    onChange={this.changeCred.bind(this, field)}/>
                  </Col>
                </Row>
              })}
              <div>
                <Button color="success" onClick={this.save.bind(this)}>
                  Save
                </Button>
              </div>
            </div>
          </Collapse>
        </CardBody>
      </Card>
    </div>;
  }
}

export default Integration;