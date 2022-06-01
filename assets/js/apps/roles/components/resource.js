import React from 'react';
import {titleize} from "../../../utils";
import {Select} from "antd";
import actions from "../actions";

const selectOptions = [
  {label: "None", value: false},
  {label: "View", value: "read"},
  {label: "Edit", value: "write"},
]

const yesOrNoSelectOptions = [
  {label: "No", value: false},
  {label: "Yes", value: "write"},
]

const changePermission = (role, resource, value) => {
  if (value) {
    role.permissions[resource] = value
  } else {
    delete role.permissions[resource]
  }
  actions.updateRole(role)
}

export default ({role, resource}) => {
  const currentPermission = role.permissions[resource.slug] || false;
  return <div className="d-flex align-items-center ml-3 pl-3">
    <div className="nowrap" style={{width: '14em'}}>{titleize(resource.description)}</div>
    <div className="py-1" style={{width: 200}}>
      <Select options={resource.permission_type === "yes-no" ? yesOrNoSelectOptions : selectOptions}
              className="w-100 p-0"
              value={currentPermission}
              onChange={changePermission.bind(null, role, resource.slug)}/>
    </div>
  </div>
}