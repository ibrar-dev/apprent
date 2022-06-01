import React, {useState} from 'react';
import {Select} from 'antd';
import Resource from './resource';
import actions from '../actions';

const batchModule = (role, resources, permission) => {
  if (permission) {
    resources.forEach(r => role.permissions[r] = permission);
  } else {
    resources.forEach(r => delete role.permissions[r]);
  }

  actions.updateRole(role)
}

const selectOptions = [
  {label: "None", value: false},
  {label: "View", value: "read"},
  {label: "Edit", value: "write"},
];

const Module = ({name, role, resources}) => {
  const moduleState = resources.reduce((acc, resource) => {
    const value = role.permissions[resource] || false;
    if (value === acc) return acc;
    return undefined;
  }, role.permissions[resources[0]] || false);

  const [isOpen, setIsOpen] = useState(false);
  return <div>
    <div className="d-flex align-items-center py-1 pl-3">
      <a onClick={() => setIsOpen(!isOpen)} className="mr-3" style={{width: '14em'}}>
        {name} <i className={`ml-3 fas fa-chevron-${isOpen ? 'down' : 'right'}`}/>
      </a>
      <div style={{width: 200}}>
        <Select options={selectOptions}
                placeholder={<div>Mixed</div>}
                className="w-100"
                value={moduleState}
                onChange={val => batchModule(role, resources, val)}/>
      </div>
    </div>
    {isOpen && resources.map(resource => <Resource key={resource.id} role={role} resource={resource}/>)}
  </div>
}

export default Module;