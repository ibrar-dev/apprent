import React from 'react';
import Uploader from '../../../../components/uploader';
import Dummy from '../../../../components/uploader/dummy';
import store from '../../store';
import classset from "classnames";
import {Button, Row, Col} from 'reactstrap';

export default (name, value, error, {component, types}, label, index) => {
  const props = store.getState();
  const change = (file) => {
    component.editField({target: {name, value: file}})
  };

  if(!(props.application.documents.models[index].file instanceof Dummy) && value.filename == props.application.documents.models[index].file.filename){
    const newFile = props.application.documents.models[index].file;
    const newFileName = newFile.filename;
    return <Col><Row className="border border-secondary rounded d-flex pb-1 align-items-content justify-content-center">
        <label className="w-100">
            <Uploader showName={true} hidden modal types={types} onChange={change} oldFile={newFile} label={newFileName}/>
        </label>
        </Row>
    </Col>
  }
  return <Col><Row className="border border-secondary rounded d-flex pb-1 align-items-content justify-content-center">
      <label className="w-100">
          <Uploader showName={true} hidden modal types={types} onChange={change} label={"Choose File"}/>
      </label>
  </Row></Col>
}