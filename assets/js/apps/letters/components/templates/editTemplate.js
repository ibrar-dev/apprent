import React from 'react';
import {Card, CardHeader, CardBody, CardFooter, Input, Button} from 'reactstrap';
import {EditorState, convertToRaw, ContentState} from 'draft-js';
import draftToHtml from 'draftjs-to-html';
import htmlToDraft from 'html-to-draftjs';
import { Editor } from 'react-draft-wysiwyg';
import shortCodes from '../shortCodes';
import actions from '../../actions';

class EditTemplate extends React.Component {
  constructor(props) {
    super(props);
    // const {contentBlocks, entityMap} = htmlToDraft('<p>Hey this <strong>editor</strong> rocks 😀</p>');
    const {contentBlocks, entityMap} = htmlToDraft(props.template.body);
    const contentState = ContentState.createFromBlockArray(contentBlocks, entityMap);
    this.state = {...props.template, template: EditorState.createWithContent(contentState)};
  }

  updateTemplate() {
    const {template, name, id} = this.state;
    const converted = draftToHtml(convertToRaw(template.getCurrentContent()));
    actions.updateTemplate({body: converted, name, id});
  }

  changeBody(template) {
    this.setState({template});
  }

  changeName({target: {value}}) {
    this.setState({name: value});
  }

  preview() {
    const {name, template} = this.state;
    const converted = draftToHtml(convertToRaw(template.getCurrentContent()));
    actions.getHtmlTemplatePreview(converted).then(r => {
      this.props.displayPreview({name}, r.data.pdf);
    });
  }

  render() {
    const {template, name} = this.state;
    return <Card>
      <CardHeader className="d-flex">
        <div className="w-75">
          <Input value={name || ''} onChange={this.changeName.bind(this)} placeholder="Template Name"/>
        </div>
        <div className="w-25 text-right">
          <Button color="info" className="mr-3" onClick={this.preview.bind(this)}>
            <i className="fas fa-eye"/> Preview
          </Button>
          <Button color="danger" onClick={this.props.selectTemplate.bind(this, null)}>
            <i className="fas fa-arrow-left"/> Back
          </Button>
        </div>
      </CardHeader>
      <CardBody className="p-0">
        <Editor editorState={template}
                editorStyle={{height: 350}}
                wrapperId="terms-wrapper"
                mention={{suggestions: shortCodes, separator: ' ', trigger: '@'}}
                onEditorStateChange={this.changeBody.bind(this)}
                toolbar={{
                  options: ['blockType', 'fontSize', 'fontFamily', 'inline', 'list', 'textAlign', 'colorPicker', 'link', 'emoji']
                }}/>
      </CardBody>
      <CardFooter>
        <Button color="success" onClick={this.updateTemplate.bind(this)}>
          Save
        </Button>
      </CardFooter>
    </Card>;
  }
}

export default EditTemplate;