import React from 'react';
import {Button, Input, Popconfirm} from "antd";
import actions from "../actions";

export default ({searchTerm, setSearchTerm, role}) => {
  return <div className="d-flex align-items-center py-1 pl-3">
    <div style={{width: '14em'}}>
      <Input value={searchTerm}
             placeholder="Search"
             onChange={({target: {value}}) => setSearchTerm(value)}
      />
    </div>
    <div className="ml-3">
      <Popconfirm title="Delete this role?" onConfirm={() => actions.deleteRole(role.id)}>
        <Button danger={true}>Delete Role</Button>
      </Popconfirm>
    </div>
  </div>
}