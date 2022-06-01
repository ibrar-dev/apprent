import React from 'react';
import {connect} from 'react-redux';
import Module from "./module";

const ResourceTree = ({roleTree, role, searchTerm}) => {
  const search = new RegExp(searchTerm, 'i');
  const modules = Object.keys(roleTree).filter(module => search.test(module));
  return modules.map(module => <Module key={module}
                                       name={module}
                                       role={role}
                                       resources={roleTree[module]}/>)

}

export default connect(({roleTree}) => ({roleTree}))(ResourceTree);