import React from "react";

class Histories extends React.Component {
  render() {
    const {lang, histories} = this.props;
    return <ul className="list-unstyled height" key={history._id}>
      <li className="listItemTitle">{lang.prev_residences}</li>
      {histories.map((history) => {
        return <React.Fragment key={history._id}>
          <li className="listItemSidebar">
            <b>{lang.address}:</b> {history.address.toString()}
          </li>
          {history.rent && <>
            <li className="listItemSidebar">
              <b>{lang.rental_amount}:</b> {history.rental_amount}
            </li>
            <li className="listItemSidebar">
              <b>{lang.landlord_name}:</b> {history.landlord_name}
            </li>
            <li className="listItemSidebar">
              <b>{lang.landlord_num}:</b> {history.landlord_phone}
            </li>
            <li className="listItemSidebar divide">
              <b>{lang.landlord_email}:</b> {history.landlord_email}
            </li>
          </>}
        </React.Fragment>
      })}
    </ul>
  }
}

export default Histories;
