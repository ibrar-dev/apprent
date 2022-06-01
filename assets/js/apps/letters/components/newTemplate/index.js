import React from 'react';
import {Card, CardHeader, CardBody, CardFooter, Input, Button} from 'reactstrap';
import {EditorState, convertToRaw} from 'draft-js';
import draftToHtml from 'draftjs-to-html';
import {Editor} from 'react-draft-wysiwyg';
import shortCodes from '../shortCodes';
import actions from '../../actions';

class NewTemplate extends React.Component {
  state = {template: EditorState.createEmpty()};

  createTemplate() {
    const {template, name} = this.state;
    const converted = draftToHtml(convertToRaw(template.getCurrentContent()));
    actions.createTemplate({body: converted, name}).then(this.props.back);
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
      this.props.preview({name}, r.data.pdf);
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
          <Button color="info" onClick={this.preview.bind(this)}>
            <i className="fas fa-eye"/> Preview
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
        <Button color="success" onClick={this.createTemplate.bind(this)}>
          Save
        </Button>
      </CardFooter>
    </Card>;
  }
}

export default NewTemplate;