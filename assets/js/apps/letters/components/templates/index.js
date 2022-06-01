import React from 'react';
import {connect} from 'react-redux';
import Template from './template';
import EditTemplate from './editTemplate';
import Preview from './preview';
import Pagination from '../../../../components/pagination';

const headers = [
  {label: '', min: true},
  {label: 'Name', sort: 'name'},
  {label: '', min: true}
];

class Templates extends React.Component {
  state = {};

  selectTemplate(template) {
    this.setState({template});
  }

  render() {
    const {letters, preview} = this.props;
    const {template} = this.state;
    if (template) return <EditTemplate template={template} displayPreview={preview}
                                       selectTemplate={this.selectTemplate.bind(this)}/>;
    return <Pagination collection={letters}
                       headers={headers}
                       component={Template}
                       additionalProps={{
                         selectTemplate: this.selectTemplate.bind(this),
                         displayPreview: preview
                       }}
                       field="template"
    />
  }
}

export default connect(({letters}) => {
  return {letters};
})(Templates);