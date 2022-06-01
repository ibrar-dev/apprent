import React from 'react';
import {ButtonGroup} from 'reactstrap';
import {withRouter} from 'react-router';
import StatusSelect from './statusSelect';
import ApplicationStatus from './applicationStatus';
import moment from "moment";

const colorKey = {
  declined: '#f9e1e6',
  approved: '#b5d3c0'
};

class ApplicationRow extends React.Component {
  state = {
    modal: false,
    description: '',
    transaction_id: '',
    amount: '',
    inserted_at: '',
    updated: false
  };

  render() {
    const {application, history} = this.props;
    return <>
      <tr key={application.id} style={{background: colorKey[application.status]}}>
        <td className="align-middle">
          {application.device_id && <i className={`fas fa-tablet-alt`}/>}
          {application.status === 'approved' && <i className={`fas fa-check`}/>}
          {application.status === 'decline' && <i className={`fas fa-times`}/>}
        </td>
        <td id={`stretch-cell-${application.id}`}>
          <div className="d-flex flex-column justify-content-between h-100">
            <div>
              <div>{application.property.name}</div>
              <div>Expected Move In: {moment(application.move_in.expected_move_in).format("YYYY-MM-DD")}</div>
            </div>
          </div>
        </td>
        <td>
          {application.move_in.unit_id && application.unit.number}
        </td>
        <td>
          <ul className="list-unstyled m-0">
            {application.persons.map(person => {
              return <li key={person.id}>
                {person.full_name}: {person.status}
              </li>;
            })}
          </ul>
        </td>
        <td>
          <ul className="list-unstyled m-0">
            {application.documents.map(doc => <li key={doc.id}>
              {doc.type} (<a href={`/api/rent_apply_documents/${doc.id}`} target="_blank">Download</a>)
            </li>)}
          </ul>
        </td>
        <td className="align-middle text-right">
          <ButtonGroup>
            <StatusSelect application={application} history={history}/>
          </ButtonGroup>
        </td>
      </tr>
      <ApplicationStatus application={application} history={history}/>
    </>
  }
}

export default withRouter(ApplicationRow);