import React from "react";
import dateFormat from './dateFormat';

class MoveIn extends React.Component {
  render() {
    const {movein, lang} = this.props;
    return <ul className="list-unstyled height">
      <li className="listItemTitle">{lang.mii}</li>
      <li className="listItemSidebar">
        <b>{lang.emi}:</b> {dateFormat(movein.expected_move_in)}
      </li>
      <li className="listItemSidebar">
        <b>{lang.unit_number}:</b> {movein.unit_number}
      </li>
    </ul>;
  }
}

export default MoveIn;