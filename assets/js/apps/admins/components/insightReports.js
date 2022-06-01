import React from 'react';
import {Button, CustomInput, FormGroup} from 'reactstrap';
import actions from "../actions";

const InsightReports = ({toggleForm, entities, entity_ids}) => {
  const filteredEntities = entities.filter((e) => entity_ids.includes(e.id));
  return (
    <>
      {
        filteredEntities.map((e) => (
          <div key={e.id}>
            <div>{e.name}</div>
            <FormGroup check inline className="ml-3">
              <CustomInput type="switch" id="weekly" name="weekly" label="Weekly" />
              <CustomInput className="ml-2" type="switch" id="daily" name="daily" label="Daily" />
            </FormGroup>
          </div>
        ))
      }
      <Button onClick={toggleForm}>
        <i className="fas fa-times text-danger" />
      </Button>
    </>
  );
};

export default InsightReports;
