import React, {useState} from 'react';
import {Input, Modal} from 'antd';
import actions from '../actions';

const NewRoleModal = ({toggle}) => {
  const [roleName, setRoleName] = useState('');
  return <Modal title="New Role"
                visible={true}
                onCancel={toggle}
                onOk={() => actions.createRole(roleName).then(toggle)}
                toggle={toggle}>
    <Input value={roleName || ''} onChange={({target: {value}}) => setRoleName(value)}/>
  </Modal>;
}

export default NewRoleModal;