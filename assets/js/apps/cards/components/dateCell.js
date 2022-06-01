import React, {useState} from "react";
import moment from "moment";
import {Popover, DatePicker} from "antd";
import actions from "../actions";

const DateCell = ({id, field, date, append, toolTipDisabled}) => {
  const [visible, setVisible] = useState(0);

  const updateDate = (val) => {
    actions.updateCard({id, [field]: val});
    setVisible(false);
  };

  // changes the date to red if it's in the past for the "Ready Date" or "Move In" columns
  const dateStyle = () => {
    const deadlineOrMoveIn = (field === "deadline" || field === "move_in_date");
    const color = (deadlineOrMoveIn && moment(date) < moment()) ? "red" : "black";
    return {color};
  };

  const hasVancantMoveOutDate = () => field === "move_out_date" && moment(date) < moment();

  const momentized = moment(date);
  const displayDate = momentized.isValid() ? (
    <span>
      {momentized.format("MM/DD/YYYY")}
      {append}
    </span>
  ) : <i className="fas fa-question" />;

  return (
    <td className={`nowrap ${!hasVancantMoveOutDate() ? "cursor-pointer" : ""}`} style={dateStyle()}>
      { hasVancantMoveOutDate() && "Vacant" }
      {
        !hasVancantMoveOutDate() && (
          <Popover
            content={(
              <DatePicker
                value={date && momentized}
                onChange={(val) => updateDate(val)}
                dateFormat="YYYY-MM-DD"
              />
            )}
            title="Update Date"
            trigger="click"
            visible={visible && !toolTipDisabled}
            onVisibleChange={setVisible}
          >
            {displayDate}
          </Popover>
        )
      }
    </td>
  );
};

export default DateCell;
