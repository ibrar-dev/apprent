import React from 'react';
import {EditorState, convertToRaw, ContentState} from 'draft-js';
import draftToHtml from 'draftjs-to-html';
import htmlToDraft from 'html-to-draftjs';
import {Editor} from 'react-draft-wysiwyg';
import {Modal, ModalHeader, ModalFooter, ModalBody, Button, Row, Col} from 'reactstrap';
import actions from '../actions';
import {savePDF} from '@progress/kendo-react-pdf';
import shortCodes from "./shortCodes";

const defaultPDF = {paperSize: 'A4', fileName: `terms.pdf`, margin: '1cm', scale: 0.6};

class PDFButton extends React.Component {
  exportPDF() {
    const element = document.getElementById('rdw-wrapper-terms-wrapper').getElementsByClassName('DraftEditor-root')[0];
    const initialHeight = element.style.height;
    element.style.height = 'auto';
    savePDF(element, defaultPDF);
    element.style.height = initialHeight;
  }

  render() {
    return <div className="rdw-option-wrapper" style={{width: 60}} onClick={this.exportPDF.bind(this)}>
      <i className="fas fa-file-pdf"/> PDF
    </div>
  }
}

class TextEditModal extends React.Component {
  constructor(props) {
    super(props);
    const contentBlock = htmlToDraft(this.props.content);
    const contentState = ContentState.createFromBlockArray(contentBlock.contentBlocks);
    this.state = {template: EditorState.createWithContent(contentState)};
  }

  changeTerms(template) {
    this.setState({template});
  }

   save() {
    const {template} = this.state;
    const {name} = this.props;
    const converted = draftToHtml(convertToRaw(template.getCurrentContent()));
    let changes;
    if(name === "Terms"){
       changes = {...this.props.property, terms: converted};
    } else if (name === "Payment Agreement Form") {
      changes = {...this.props.property}
      changes.settings.agreement_text = converted
    }else{
      changes = {...this.props.property};
      changes.settings.verification_form = converted;
    }
    actions.updateProperty(changes).then(() => {
      this.setState({message: 'Terms Saved!'});
      setTimeout(() => this.setState({message: null}), 2500);
      this.props.close()
    }).catch(() => {
    })
  }

  preview() {
    const {template, showPreview} = this.state;
    if(!showPreview) {
      const converted = draftToHtml(convertToRaw(template.getCurrentContent()));
      actions.getHtmlTemplatePreview(converted).then(r => {
        const data = r.data.pdf;
        this.setState({preview: data ? {template, data} : null, showPreview: true});
      });
    }else{
      this.setState({showPreview: false})
    }
  }

  togglePreview(){
    this.setState({showPreview: !this.state.showPreview})
  }

  render() {
    const {close, property, name, pdf} = this.props;
    const {template, message, preview, showPreview} = this.state;
    const previewButton =  <div className="rdw-option-wrapper" style={{width: 85}} onClick={this.preview.bind(this)}>
      <i className="fas fa-eye"/> Preview
    </div>;
    return <Modal isOpen={true} size="lg">
      <ModalHeader toggle={close}>
        {name} for {property.name}
      </ModalHeader>
      <ModalBody>
        {showPreview ? <>
          <Row>
            <Col className="d-flex justify-content-end">
              <a onClick={this.preview.bind(this)}>X</a>
            </Col>
          </Row>
          <Row>
            <Col>
            <iframe src={`data:application/pdf;base64,` + preview.data} height={550} width="100%"/>
            </Col>
          </Row>
        </> : <>
          {this.state.message && <h5 className="m-0 text-center">{message}</h5>}
          <Editor editorState={template}
                  editorStyle={{height: 350}}
                  wrapperId="terms-wrapper"
                  mention={{suggestions: shortCodes, separator: ' ', trigger: '@'}}
                  onEditorStateChange={this.changeTerms.bind(this)}
                  toolbarCustomButtons={pdf ? [<PDFButton/>, previewButton] : [previewButton]}
                  toolbar={{
                    options: ['blockType', 'fontSize', 'fontFamily', 'inline', 'list', 'textAlign', 'colorPicker', 'link', 'emoji'],
                    fontFamily: {options: ['Arial', 'Georgia', 'Impact', 'Tahoma', 'Times New Roman', 'Arizonia'] }
                  }}/>
          </>}
      </ModalBody>
      <ModalFooter>
        <Button color="danger" onClick={close}>Cancel</Button>
        <Button color="success" onClick={this.save.bind(this)}>Save</Button>
      </ModalFooter>
    </Modal>
  }
}

export default TextEditModal;