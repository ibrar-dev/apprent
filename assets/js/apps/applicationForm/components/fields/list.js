import React from 'react';
import Multiselect from 'react-widgets/lib/Multiselect';
import {Transition} from 'react-transition-group';

const Invisible = ({in: inProp}) => (
  <Transition in={inProp} timeout={0}>
    {() => <div className="d-none"/>}
  </Transition>
);

export default (name, value, error, {component}) => {
  const addName = (component, nameToAdd) => {
    const nameList = value.concat([nameToAdd]);
    component.editField({target: {value: nameList, name}});
  };
  const change = (component, nameToChange, {action: action, dataItem: item}) => {
    if (action === 'remove') {
      const nameList = value.filter(n => n !== item);
      component.editField({target: {value: nameList, name}});
    }
  };
  return <Multiselect allowCreate={true}
                      name={name}
                      className={error ? 'is-invalid' : ''}
                      onChange={change.bind(null, component)}
                      onCreate={addName.bind(null, component)}
                      value={value}
                      popupTransition={Invisible}
                      data={value}/>
};