import React from 'react';
import {connect} from 'react-redux';
import actions from '../actions';
import Document from '../models/document';
import utils from './utils';

const documentTypes = 'application/*,image/*';

class DocumentForm extends React.Component {
  editField(e) {
    actions.editCollection('documents', this.props.index, e.target.name, e.target.value);
  }

  deleteEmployment() {
    actions.deleteCollection('documents', this.props.document._id);
  }

  render() {
    const {document, index, lang} = this.props;
    const userField = utils.userField.bind(this, document);
    return <div className="card">
      <div className="card-header">
        {lang.document} #{index + 1}
        {index > 1 && <a className="delete-button" onClick={this.deleteEmployment.bind(this)}>
          <i className="fas fa-trash"/>
        </a>}
      </div>
      <div className="card-body">
        {index < 2 && <div className="row margin-row">
          <div className="col-md-3">{lang.type}</div>
          <div className="col-md-9">{document.type}</div>
        </div>}
        {index > 1 && userField('type', lang.type, 'select', {options: ['Driver\'s License', 'Pay Stub']}, index)}
        {userField('file', lang.file, 'file', {types: documentTypes}, index)}
      </div>
    </div>
  }
}

class Documents extends React.Component {
  addDocument() {
    actions.addToCollection('documents', new Document());
  }

  render() {
    const {application:{documents}, lang} = this.props;
    return <div>
      {documents.map((document, index) => {
        return <DocumentForm key={document._id} index={index} lang={lang} document={document}/>;
      })}
      <div className="card">
        <div className="card-body text-center">
          {lang.required_document}
        </div>
      </div>
      <div className="add-button" onClick={this.addDocument.bind(this)}>
        <button>
          <i className="fas fa-plus"/>
        </button>
        {lang.add_document}
      </div>
    </div>;

  }
}

export default connect((s) => {
  return {application: s.application, lang: s.language}
})(Documents);
