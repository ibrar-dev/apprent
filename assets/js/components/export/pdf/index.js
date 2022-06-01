import React from 'react';
import {savePDF} from '@progress/kendo-react-pdf';
import {Button, Modal, ModalHeader, ModalBody, ModalFooter, Row, Col, Input} from "reactstrap";
import {convertToRaw} from "draft-js";
import {Editor} from 'react-draft-wysiwyg';
import draftToHtml from 'draftjs-to-html';
import Select from '../../select';
import Checkbox from '../../fancyCheck';
import actions from '../actions';
import NewCategory from './newCategory';
import NewRecipient from './newRecipient';

const defaultPDF = {
  paperSize: 'A4',
  margin: '1cm',
  scale: 0.6,
  proxyURL: '/api/exports',
  forceProxy: true,
  proxyTarget: "pdf-doc-frame",
  pageTemplate: props => (
    <div style={{position: "absolute", bottom: "12px", left: "47%"}}>
      Page {props.pageNum} of {props.totalPages}
    </div>
  )
};

class ExportPDF extends React.Component {
  state = {categories: [], recipients: [], recipient_ids: [], notes: '', subject: ''};

  componentDidMount() {
    actions.fetchCategories().then(r => {
      this.setState({categories: r.data});
    });
    actions.fetchRecipients().then(r => {
      this.setState({recipients: r.data});
    })
  }

  toggleModal() {
    this.setState({modalOpen: !this.state.modalOpen, name: this.props.name});
  }

  addCategory(category) {
    const {categories} = this.state;
    categories.push(category);
    this.setState({categories: [...categories], category_id: category.id});
  }

  addRecipient(recipient) {
    const {recipients, recipient_ids} = this.state;
    recipients.push(recipient);
    recipient_ids.push(recipient.id);
    this.setState({recipients: [...recipients], recipient_ids: [...recipient_ids]});
  }

  exportPDF() {
    const {category_id, name, notes, message, recipient_ids, sendMode, subject} = this.state;
    const {pdfParams, target, invisible} = this.props;
    const proxyData = {category_id, notes};
    if (sendMode) {
      proxyData.message = draftToHtml(convertToRaw(message.getCurrentContent()));
      proxyData.subject = subject;
      proxyData.recipient_ids = recipient_ids;
    }
    const fullPdfParams = {...defaultPDF, ...pdfParams, fileName: name, proxyData};
    const element = document.getElementById(target);
    if (invisible) element.style.display = 'initial';
    savePDF(element, fullPdfParams);
    if (invisible) element.style.display = 'none';
    this.setState({modalOpen: !this.state.modalOpen});
  }

  change({target: {name, value, checked, type}}) {
    this.setState({[name]: type === 'checkbox' ? checked : value});
  }

  changeMessage(message) {
    this.setState({message});
  }

  render() {
    const toggle = this.toggleModal.bind(this);
    const {modalOpen, categories, category_id, name, notes, sendMode, message, recipient_ids, recipients, subject} = this.state;
    const change = this.change.bind(this);
    return <>
      <Button {...this.props.buttonProps} className="px-2 py-1 h-100" onClick={toggle} outline
              color="info">
        <i className="fas fa-file-pdf" style={{fontSize: '140%'}}/>
      </Button>
      <Modal toggle={toggle} isOpen={modalOpen} size="xl">
        <ModalHeader toggle={toggle}>Export</ModalHeader>
        <ModalBody>
          <Row>
            <Col sm={3}>Category</Col>
            <Col className="d-flex">
              <div className="flex-auto">
                <Select name="category_id" onChange={change} value={category_id} options={categories.map(c => {
                  return {label: c.name, value: c.id};
                })}/>
              </div>
              <NewCategory parent={this}/>
            </Col>
          </Row>
          <Row className="mt-3">
            <Col sm={3}>Name</Col>
            <Col>
              <Input name="name" onChange={change} value={name}/>
            </Col>
          </Row>
          <Row className="mt-3">
            <Col sm={3}>Notes</Col>
            <Col>
              <Input type="textarea" name="notes" rows={4} onChange={change} value={notes}/>
            </Col>
          </Row>
          <Row>
            <Col className="d-flex align-items-center">
              <Checkbox inline checked={!!sendMode} name="sendMode" onChange={change}/>
              <div className="ml-2">Send to recipients</div>
            </Col>
          </Row>
          {sendMode && <>
            <Row className="mt-3">
              <Col sm={3}>Recipients</Col>
              <Col className="d-flex">
                <div className="flex-auto">
                  <Select multi
                          options={recipients.map(r => {
                            return {label: `${r.name}<${r.email}>`, value: r.id};
                          })}
                          name="recipient_ids"
                          onChange={change} value={recipient_ids}/>
                </div>
                <NewRecipient parent={this}/>
              </Col>
            </Row>
            <Row className="mt-3">
              <Col sm={3}>Subject</Col>
              <Col>
                <Input name="subject" onChange={change} value={subject}/>
              </Col>
            </Row>
            <Row className="mt-3">
              <Col sm={3}>Message</Col>
              <Col>
                <Editor editorState={message}
                        editorStyle={{height: 350}}
                        wrapperId="terms-wrapper"
                        onEditorStateChange={this.changeMessage.bind(this)}
                        toolbar={{
                          options: ['blockType', 'fontSize', 'fontFamily', 'inline', 'list', 'textAlign', 'colorPicker', 'link', 'emoji']
                        }}/>
              </Col>
            </Row>
          </>}
        </ModalBody>
        <ModalFooter>
          <Button color="danger" onClick={toggle}>Cancel</Button>
          <Button color="success" onClick={this.exportPDF.bind(this)}>Save</Button>
        </ModalFooter>
      </Modal>
      <iframe className="border-0" style={{width: 0, height: 0}} name="pdf-doc-frame"/>
    </>
  }
}

export default ExportPDF;