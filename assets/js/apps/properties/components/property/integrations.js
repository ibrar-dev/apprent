import React from 'react';
import Select from '../../../../components/select';
import Checkbox from '../../../../components/fancyCheck';
import {Col, Row, Button} from "reactstrap";
import actions from "../../actions";

const AVAILABLE_INTEGRATIONS = {
  Yardi: [
    ['Residents', 'sync_residents'],
    ['Ledgers', 'sync_ledgers'],
    ['Payments', 'sync_payments']
  ]};

class Integrations extends React.Component {
  state = {settings: this.props.property.settings, bankAccounts: []};

  save() {
    const {settings} = this.state;
    actions.updateProperty({id: this.props.property.id, settings});
  }

  change({target: {name, value}}) {
    this.setState({settings: {...this.state.settings, [name]: value}});
  }

  toggle({target: {name, checked}}) {
    this.setState({settings: {...this.state.settings, [name]: checked}});
  }

  toggleFieldFor(label, fieldName) {
    const {settings} = this.state;
    return <div className="mb-1" key={fieldName}>
      <Checkbox label={label} inline name={fieldName} checked={settings[fieldName]} value={settings[fieldName]}
                onChange={this.toggle.bind(this)}/>
    </div>;
  }

  render() {
    const {settings: {integration}} = this.state;
    const change = this.change.bind(this);
    return <div>
      <Row className="mb-2 d-flex align-items-center">
        <Col sm={1}>
          Integration:
        </Col>
        <Col>
          <Select options={Object.keys(AVAILABLE_INTEGRATIONS).map(i => ({label: i, value: i}))} value={integration}
                  name="integration" onChange={change}/>
        </Col>
      </Row>
      {integration && <div>
        <h4>Available integrations for {integration}:</h4>
        {AVAILABLE_INTEGRATIONS[integration].map(([label, field]) => {
          return this.toggleFieldFor(label, field)
        })}
      </div>}
      <div className="d-flex justify-content-between">
        <Button color="success" className="mt-2" onClick={this.save.bind(this)}>
          Save
        </Button>
      </div>
    </div>;
  }
}

export default Integrations;