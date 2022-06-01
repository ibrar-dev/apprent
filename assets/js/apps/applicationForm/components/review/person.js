import React from "react";
import dateFormat from './dateFormat';

class Person extends React.Component {
  render() {
    const person = this.props.person;
    const {lang} = this.props;
    return <div className="col-md-4">
      <h4>{person.status}</h4>
      <ul className="list-unstyled">
        <li className="listItemSidebar">
          <b>{lang.name}:</b> {person.full_name}
        </li>
        <li className="listItemSidebar">
          <b>{lang.email}:</b> {person.email}
        </li>
        <li className="listItemSidebar">
          <b>{lang.dob}:</b> {dateFormat(person.dob)}
        </li>
        <li className="listItemSidebar">
          <b>{lang.home_phone}:</b> {person.home_phone}
        </li>
        <li className="listItemSidebar">
          <b>{lang.work_phone}:</b> {person.work_phone}
        </li>
        <li className="listItemSidebar">
          <b>{lang.cell_phone}:</b> {person.cell_phone}
        </li>
        <li className="listItemSidebar">
          <b>{lang.drivers_license}:</b> {person.dl_number}
        </li>
        <li className="listItemSidebar">
          <b>{lang.state}:</b> {person.dl_state}
        </li>
      </ul>
    </div>;
  }
}

export default Person;