import React from 'react';
import {connect} from 'react-redux';
import Pagination from '../../../components/pagination';
import TemplateForm from './templateForm';
import Template from './template';
import actions from '../actions';

const headers = [
  {label: '', min: true},
  {label: 'Name', sort: 'name'},
  {label: '', min: true}
];

class ReportTemplates extends React.Component {
  state = {};

  _filters() {

  }

  render() {
    const {templates, template} = this.props;
    if (template) return <TemplateForm template={template}/>;
    const titleBar = <div>
      Report Templates
      <button className="btn btn-sm btn-success mt-0 mx-4"
              onClick={actions.setTemplate.bind(null, {groups: [], accounts: []})}>
        New Template
      </button>
    </div>;
    return <Pagination title={titleBar}
                       collection={templates}
                       component={Template}
                       headers={headers}
                       filters={this._filters()}
                       field="template"
    />;
  }
}

export default connect(({templates, template}) => {
  return {templates, template};
})(ReportTemplates);