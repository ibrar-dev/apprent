import React from 'react';
import {connect} from "react-redux";
import {Button, Row, Col} from "reactstrap";
import CheckBox from "../../../../../components/fancyCheck";
import Select from "../../../../../components/select";
import actions from "../../../actions";

class Create extends React.Component {
  state = {visible: true};

  toggleVisible() {
    this.setState({visible: !this.state.visible});
  }

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  createDoc() {
    const {tenant} = this.props;
    const {template, visible} = this.state;
    actions.createLetter(tenant.id, template.id, visible);
  }

  changeTemplate({target: {value}}) {
    const template = this.props.propertyTemplates.find(x => x.id === value);
    this.setState({template});
  }

  render() {
    const {tenant, propertyTemplates} = this.props;
    const {template, visible} = this.state;
    return <div>
      <h4 className="mb-2 text-info">Create Document</h4>
      <Row>
        <Col className="d-flex">
          <div className="mr-3 d-flex align-items-center">
            <CheckBox checked={visible} onChange={this.toggleVisible.bind(this)}/> &nbsp;Visible
          </div>
          <div className="labeled-box w-100">
            <Select value={template ? template.id : ''} name="templateId"
                    placeholder="None"
                    options={propertyTemplates.map(t => {
                      return {label: t.name, value: t.id}
                    })}
                    onChange={this.changeTemplate.bind(this)}/>
            <div className="labeled-box-label">Template Type</div>
          </div>
        </Col>
        <Col>
          <Button className="btn-block btn-success" disabled={!template} onClick={this.createDoc.bind(this, "file")}>
            Create
          </Button>
        </Col>
      </Row>
      <div className="text-center mt-4">
        {!template && <div className="d-flex" style={{width: 1000, paddingTop: 40}}>
          <i className="fas fa-exclamation-circle text-danger mr-2"/>
          <h6 className='align-self-center' style={{color: '#888d96'}}>
            Select a template type or make a new template in order to create a document.
          </h6>
        </div>}
        {template && <iframe style={{width: 1000, height: 1200}}
                             src={`/api/letter_templates/${template.id}?tenant_id=${tenant.id}`}/>}
      </div>
    </div>;
  }
}

export default connect(({tenant, propertyTemplates}) => {
  return {tenant, propertyTemplates};
})(Create);