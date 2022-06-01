import React from 'react';
import {Button, ButtonGroup} from 'reactstrap';
import actions from '../actions';
import confirmation from '../../../components/confirmationModal';

class Template extends React.Component {
  deleteTemplate() {
    confirmation('Really delete this template entirely? This action cannot be undone').then(() => {
      actions.deleteTemplate(this.props.template);
    }).catch(() => {
    });
  }

  render() {
    const {template} = this.props;
    return <tr>
      <td className="align-middle">
        <a onClick={this.deleteTemplate.bind(this)}>
          <i className="fas fa-times text-danger"/>
        </a>
      </td>
      <td className="align-middle">
        {template.name}
      </td>
      <td>
        <ButtonGroup>
          <Button color="info" onClick={actions.setTemplate.bind(null, template)} size="sm" outline>
            Edit
          </Button>
          <Button color="success" onClick={actions.duplicateTemplate.bind(null, template)} size="sm" outline>
            Duplicate
          </Button>
        </ButtonGroup>
      </td>
    </tr>;
  }
}

export default Template;