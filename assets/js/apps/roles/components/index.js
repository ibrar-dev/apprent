import React from 'react';
import {connect} from 'react-redux';
import Role from './role';
import Header from './head';

const RolesApp = ({roles}) => {
    const roleNodes = roles.map(role => <Role key={role.id} role={role}/>)
    return <>
      <Header/>
      {roleNodes}
    </>;
}

export default connect(({roles}) => ({roles}))(RolesApp)