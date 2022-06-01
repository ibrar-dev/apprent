import React from 'react';
import {connect} from 'react-redux';
import Pagination from '../../../components/pagination';
import ApplicationRow from "./applicationRow";
import PropertySelect from "../../../components/propertySelect";
import actions from "../actions";
import TagsInput from 'react-tagsinput';
import ProgressModal from './progressModal';

class Applications extends React.Component {
  constructor(props) {
  super(props);
    this.headers = [
      {label: 'Property', sort: null},
      {label: 'Primary Applicant', sort: null},
      {label: 'Language', sort: null},
      {label: 'Email', sort: null},
      {label: 'Started On', sort: 'start_time'},
      {label: 'Last Updated', sort: 'updated_at'},
      {label: 'Progress', sort: null},
    ];

    this.state = {
      tags: [],
      modalApp: {},
    };
    this.tagChange = this.tagChange.bind(this);
    this.displayModal = this.displayModal.bind(this);
  }

  tagChange(tags) {
    this.setState({...this.state, tags})
  }

  displayModal(appId) {
    if(!!appId) {
      const {applications} = this.props;
      const app = applications &&  applications.find(a => a.id === appId)
      app && this.setState({modalApp: app});
    } else {
      this.setState({modalApp: {}});
    }
  }

  _filters() {
    const {tags} = this.state;
    return (
      <TagsInput
        value={tags}
        onChange={this.tagChange}
        onlyUnique
        className="react-tagsinput flex-fill mb-2"
        inputProps={{
          className: 'react-tagsinput-input',
          placeholder: 'Add a search term',
          style: {width: 'auto'}
        }}
      />
    )
  }

  filtered() {
    const {applications} = this.props;
    const {tags} = this.state;
    if(tags.length === 0) return applications;

    return applications.filter(({name, email}) => {
      return (
        (!!name && tags.some(tag => name.toLowerCase().includes(tag.toLowerCase())))
        || tags.some(tag => email.toLowerCase().includes(tag.toLowerCase()))
      )
    });
  }

  render() {
    const {modalApp} = this.state;
    const {properties, property} = this.props;

    if (properties.length == 0) {
      return (
        <p>Loading</p>
      )
    }

    return <React.Fragment>
      {
        modalApp.id && (
          <ProgressModal
            application={modalApp}
            onClose={() => this.displayModal(null)}
          />
        )
      }
      <Pagination
        title={
          <PropertySelect
            properties={properties}
            property={property}
            onChange={actions.setProperty}
          />
        }
        additionalProps={{ property, displayModal: this.displayModal }}
        collection={this.filtered()}
        component={ApplicationRow}
        headers={this.headers}
        filters={this._filters()}
        field="application"/>
    </React.Fragment>
  }
}

export default connect(({applications, properties, property}) => {
  return {applications, properties, property};
})(Applications);
