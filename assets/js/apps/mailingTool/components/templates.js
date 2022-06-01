import React, {Component} from 'react';
import {connect} from 'react-redux';
import actions from '../actions';
import {Row, Col, Card, CardTitle, CardHeader, Collapse, CardBody, Button, ButtonGroup, Input, Modal, ModalHeader, ModalFooter, ModalBody, FormGroup, Label } from 'reactstrap';
import {ContentState, convertFromHTML} from 'draft-js';
import {convertToRaw} from 'draft-js';
import draftToHtml from 'draftjs-to-html';
import confirmation from '../../../components/confirmationModal';
import canEdit from '../../../components/canEdit';
import PropertySelect from "../../techs/components/list/propertySelect";

class Templates extends Component {
  state = {
    expand: false,
    filterVal: '',
    edited: false,
    triggered: false,
    currentTemplate: '',
    propertyModal: false,
    property_ids: [],
    template_id: ''
  }

  togglePropertyModal(t){
    this.setState(prevState => ({
      propertyModal: !prevState.propertyModal,
      template_id: t.id,
      property_ids: []
    })
    )
  }

  propertyTemplates(){
    let propertyArray = []
    let properties = this.props.propertiesTemplate;
    for ( var i = 0; i < properties.length; i++) {
      propertyArray.push(properties[i].property_id)
    }
    this.setState({property_ids: propertyArray})
  }

  addToPropertyIDs(id) {
    let propertyArray = this.state.property_ids;
    propertyArray.includes(id) ? propertyArray.splice(propertyArray.indexOf(id), 1) : propertyArray.push(id);
    this.setState({...this.state, property_ids: propertyArray})
  }


  changeBackdrop(e) {
    let value = parseInt(e.target.value);
    this.setState({ backdrop: value });
  }

  componentDidUpdate(prevProps, prevState) {
    if(this.state.currentTemplate == true && this.state.currentTemplate != 1){
      actions.fetchTemplateProperties({template_id: this.state.currentTemplate })
      this.propertyTemplates.bind(this)()
    }
    if(prevState.currentTemplate !== this.state.currentTemplate){
      actions.fetchTemplateProperties({template_id: this.state.currentTemplate })
      this.propertyTemplates.bind(this)()
    }
  }

  toggleExpand() {
    this.setState({expand: !this.state.expand})
  }

  setTemplate(template) {
    this.propertyTemplates.bind(this)()
    this.setState({triggered: true, currentTemplate: template.id, edited: true })
    const html = convertFromHTML(template.body);
    const converted = ContentState.createFromBlockArray(html.contentBlocks, html.entityMap);
    this.props.setBody(template.subject, converted);
  }


  templateAction(template){
    const {subject, body} = this.props.state;
    const bodyHTML = draftToHtml(convertToRaw(body.getCurrentContent()));
    const html = convertFromHTML(template.body);
    const id = template.id
    const converted = ContentState.createFromBlockArray(html.contentBlocks, html.entityMap);
    {this.state.edited ?
      confirmation('Please confirm that you would like to save this template.').then(() => {
        actions.editTemplate({id, subject, body: bodyHTML})
      })    :
      this.setState({ edited: true })
    }
}

  deleteTemplate(template){
    const id = parseInt(template.id)
      confirmation('Please confirm that you would like to delete this template.').then(() => {
        actions.deleteTemplate(id)})
  }

  updateFilter(e) {
    this.setState({...this.state, filterVal: e.target.value})
  }

  assignProperty() {
    const {property_ids, template_id} = this.state
    if (property_ids.length > 1) {
      confirmation('Please confirm that you would like to assign the specified properties to this template.').then(() =>{
        actions.deleteAllTemplates({template_id})
        for ( var id in property_ids) {
          actions.propertyTemplateAction({template_id: template_id, property_id: property_ids[id]})
        }
        this.setState({propertyModal: false})
      })
    }
    else{
      const id = parseInt(this.state.property_ids)
        confirmation('Please confirm that you would like to assign the specified property to this template.').then(() => {
          actions.deleteAllTemplates({template_id})
          actions.propertyTemplateAction({template_id: template_id, property_id: id})
        })
    }
    this.setState({propertyModal: false})
  }

  filteredTemplates() {
    const {filterVal} = this.state;
    const {templates} = this.props;
    const filter = new RegExp(filterVal, 'i')
    return templates.filter(t => filter.test(t.subject))
  }

  render() {
    const {expand, filterVal} = this.state;
    const {properties, activePresets} = this.props;

    if (properties.length == 0) {
      return <div>Loading...</div>
    }

    const style = {
      border: '1px solid grey',
      borderRadius: '5px',
      maxHeight: '150px',
      overflowY: 'scroll'
    };
    return <Row>
      <Col>
        <Card>
          <CardHeader onClick={this.toggleExpand.bind(this)} className="d-flex justify-content-between">
            <span>Templates</span>
            {expand && <Input className="w-50" onClick={e => e.stopPropagation()} value={filterVal} onChange={this.updateFilter.bind(this)}/>}
          </CardHeader>
          <Collapse isOpen={expand}>
            <CardBody>
              <Row>
                {this.filteredTemplates().map(t => {
                  return <Col key={t.id} sm="6" >
                    <Card body onClick={this.setTemplate.bind(this, t)} >
                    <CardTitle  >{t.subject}</CardTitle>
                      {canEdit(["Regional", "Super Admin"]) && <div className='d-flex justify-content-around'>
                        <ButtonGroup>
                      <Button onClick={this.templateAction.bind(this, t)} className="btn btn-success btn-md"  disabled={this.state.currentTemplate != t.id}>{this.state.edited ? "Save Template" : "Edit Template"}</Button>
                      <Button onClick={this.togglePropertyModal.bind(this, t)} className="btn btn-warning btn-md" disabled={this.state.currentTemplate != t.id} >Assign a Property </Button>
                      <Button onClick={this.deleteTemplate.bind(this, t)} className="btn btn-danger btn-md" disabled={this.state.currentTemplate != t.id} >Delete Template </Button>
                        </ButtonGroup>
                      </div>
                      }

                    </Card>
                  </Col>
                })}
                <Modal isOpen={this.state.propertyModal} toggle={this.togglePropertyModal.bind(this)} className={this.props.className}>
                  <ModalHeader toggle={this.togglePropertyModal.bind(this)}> Assign a Property</ModalHeader>
                  <ModalBody className="d-flex justify-content-between">
                    <Col md={12} style={style}>
                      {properties.map((p, index) => {
                        return (<PropertySelect key={index} property={p} checked={this.addToPropertyIDs.bind(this)}
                                                property_ids={this.state.property_ids} />)
                      })}
                    </Col>
                  </ModalBody>
                  <ModalFooter>
                    <Button color="danger" onClick={this.togglePropertyModal.bind(this)}>Back</Button>{''}
                    <Button color="success" onClick={this.assignProperty.bind(this)}>Save</Button>{''}

                  </ModalFooter>
                </Modal>
              </Row>
            </CardBody>
          </Collapse>
        </Card>
      </Col>
    </Row>
  }
}

export default connect(({templates, activePresets, properties, propertiesTemplate}) => {
  return {templates, activePresets, properties, propertiesTemplate}
})(Templates)
