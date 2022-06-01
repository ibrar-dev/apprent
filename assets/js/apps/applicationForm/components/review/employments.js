import React from "react";

class Employments extends React.Component {
  render() {
    const {income, employments, lang} = this.props;
    return <ul className="list-unstyled height">
      <li className="listItemTitle">{lang.employment_info}</li>
      {employments.map((employment) => {
        return <React.Fragment key={employment._id}>
          <li className="listItemSidebar">
            <b>{lang.employer}:</b> {employment.employer}
          </li>
          <li className="listItemSidebar">
            <b>{lang.supervisor_name}:</b> {employment.supervisor}
          </li>
          <li className="listItemSidebar">
            <b>{lang.address}:</b> {employment.address.toString()}
          </li>
          <li className="listItemSidebar">
            <b>{lang.phoneNumber}:</b> {employment.phone}
          </li>
          <li className="listItemSidebar">
            <b>{lang.email}:</b> {employment.email}
          </li>
          <li className="listItemSidebar">
            <b>{lang.employment_duration}:</b> {employment.duration}
          </li>
          <li className="listItemSidebar divide">
            <b>{lang.salary}:</b> ${employment.salary}/month
          </li>
        </React.Fragment>
      })}
      <li className="listItemSidebar">
        {income && income.salary && <div>
          <u className="font-weight-bold">{lang.other_income}</u>
          <ul className="list-unstyled border-0">
            <li className="listItemSidebar"><b>{lang.description}:</b> {income.description}</li>
            <li className="listItemSidebar"><b>{lang.salary}:</b> {income.salary}</li>
          </ul>
        </div>}
      </li>
    </ul>;
  }
}

export default Employments;
