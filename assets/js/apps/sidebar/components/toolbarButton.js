import React, {useState} from "react";
import {connect} from "react-redux";
import {Button, Tooltip} from "reactstrap";
import actions from "../actions";

const ToolbarButton = ({selected, roleName, icon}) => {
  const [tooltip, setTooltip] = useState(false);

  const hover = (show) => {
    if (show === tooltip) return;
    setTooltip(show);
  };

  const id = `role-button-${roleName.toLowerCase().replace(" ", "-")}`;
  return (
    <div style={{marginTop: 20, marginBottom: 20}}>
      <Button
        style={{flex: "auto", boxShadow: "none"}}
        color={`sidebar-info${selected ? "-hover" : ""}`}
        id={id}
        onMouseEnter={() => hover(true)}
        onMouseLeave={() => hover(false)}
        onClick={() => actions.setRole(roleName)}
      >
        <i className={icon} />
      </Button>
      <Tooltip placement="top" isOpen={tooltip} target={id}>
        {roleName}
      </Tooltip>
    </div>
  );
};

const mapStateToProps = ({role}) => ({role});
export default connect(mapStateToProps)(ToolbarButton);
