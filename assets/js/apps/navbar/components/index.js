import React, {useState} from "react";
import {connect} from "react-redux";
import {
  Popover, PopoverBody, ListGroup, ListGroupItem,
} from "reactstrap";
import ProfileModal from "./profileModal";
import tenantSearch from "./tenantSearch";

const Navbar = ({admin}) => { 
  return (
    <>
      <li className="mr-1" style={{width: 340}}>
        {tenantSearch()}
      </li>
      <li className="nav-item h-100">
        <span className="nav-link mr-3 h-100 d-flex align-items-center">{admin.name}</span>
      </li>
    </>
  )
}

export default connect(({admin}) => ({admin}))(Navbar);
