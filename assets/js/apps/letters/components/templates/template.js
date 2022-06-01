import React from 'react';
import {ButtonGroup, Button} from 'reactstrap';
import actions from '../../actions';
import confirmation from '../../../../components/confirmationModal';

class Template extends React.Component {
  state = {};

  edit() {
    const {selectTemplate, template} = this.props;
    selectTemplate(template);
  }

  preview() {
    const {template, displayPreview} = this.props;
    actions.getTemplatePreview(template.id).then(r => {
      displayPreview(template, r.data.pdf);
    })
  }

  deleteTemplate() {
    confirmation('Really delete this template?').then(() => {
      actions.deleteTemplate(this.props.template.id);
    });
  }

  render() {
    const {template} = this.props;
    return <tr>
      <td/>
      <td className="align-middle">{template.name}</td>
      <td>
        <ButtonGroup>
          <Button onClick={this.edit.bind(this)} color="info" outline>
            <i className="fas fa-pencil-alt"/>
          </Button>
          <Button onClick={this.preview.bind(this)} color="info" outline>
            <i className="fas fa-eye"/>
          </Button>
          <Button onClick={this.deleteTemplate.bind(this)} color="info" outline>
            <i className="fas fa-times"/>
          </Button>
        </ButtonGroup>
      </td>
    </tr>;
  }
}

export default Template;