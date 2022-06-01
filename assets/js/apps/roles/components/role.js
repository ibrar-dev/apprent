import React, {useState} from 'react';
import ResourceTree from './resourceTree';
import RoleControl from './roleControl';

const Role = ({role}) => {
  const [folded, setFolded] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  return <div className="ml-4 my-4 py-2">
    <h4 className="d-flex align-items-center">
      <a onClick={() => setFolded(!folded)}>
        {role.name} <i className={`ml-3 fas fa-chevron-${folded ? 'right' : 'down'}`}/>
      </a>
    </h4>
    {!folded && <RoleControl role={role} searchTerm={searchTerm} setSearchTerm={setSearchTerm}/>}
    {!folded && <ResourceTree role={role} searchTerm={searchTerm}/>}
  </div>;
}

export default Role;