import React from "react";

class Contacts extends React.Component {
  render() {
    const {contacts, lang} = this.props;
    return <ul className="list-unstyled height">
      <li className="listItemTitle">
        {lang.emergency_contacts}
      </li>
      {contacts.map((contact) => {
        return <React.Fragment key={contact._id}>
          <li className="listItemSidebar">
            <b>{lang.name}:</b> {contact.name}
          </li>
          <li className="listItemSidebar">
            <b>{lang.relationship}:</b> {contact.relationship}
          </li>
          <li className="listItemSidebar">
            <b>{lang.email}:</b> {contact.email.toString()}
          </li>
          <li className="listItemSidebar divide">
            <b>{lang.phoneNumber}:</b> {contact.phone}
          </li>
        </React.Fragment>
      })}
    </ul>
  }
}

export default Contacts;
