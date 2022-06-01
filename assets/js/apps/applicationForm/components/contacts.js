import React from 'react';
import {connect} from 'react-redux';
import actions from '../actions';
import Contact from '../models/contact';
import utils from './utils';

class ContactForm extends React.Component {
  editField(e) {
    actions.editCollection('emergency_contacts', this.props.index, e.target.name, e.target.value);
  }

  deleteContact() {
    actions.deleteCollection('emergency_contacts', this.props.contact._id);
  }

  render() {
    const {lang, contact, index} = this.props;
    const userField = utils.userField.bind(this, contact);
    return <div className="card">
      <div className="card-header">
        {lang.contact} #{index + 1}
        {
          index > 0 && (
            <a className="delete-button" onClick={this.deleteContact.bind(this)}>
              <i className="fas fa-trash"/>
            </a>
          )
        }
      </div>
      <div className="card-body pt-0">
        {userField('name', lang.name)}
        {userField('phone', lang.phoneNumber, 'phone')}
        {userField("email", lang.email)}
        {userField('relationship', lang.relationship)}
      </div>
    </div>
  }
}

class Contacts extends React.Component {
  addContact() {
    const {occupants} = this.props.application;
    actions.addToCollection('emergency_contacts', new Contact({occupants}));
  }

  render() {
    const {emergency_contacts: contacts} = this.props.application;
    const {lang} = this.props;
    return <div>
      {contacts.map((contact, index) => {
        return <ContactForm key={contact._id} index={index} lang={lang} contact={contact}/>;
      })}
      <div className="add-button" onClick={this.addContact.bind(this)}>
        <button>
          <i className="fas fa-plus"/>
        </button>
        {lang.add_contact}
      </div>
    </div>;

  }
}

export default connect((s) => {
  return {application: s.application, lang: s.language}
})(Contacts);
