import React from 'react';
import {ButtonGroup} from 'reactstrap';
import moment from 'moment';
import icons from '../../../components/flatIcons';

const ApplicationRow = ({application, property, displayModal}) => (
  <>
    <tr key={application.id}>
      <td>{property.name}</td>
      <td>{application.name}</td>
      <td>
        <img
          src={application.lang === "English" ? icons.united_states : icons.spain}
          height="15"
        />
      </td>
      <td>{application.email}</td>
      <td>{application.start_time && moment(application.start_time).format('MMMM Do, h:mm a')}</td>
      <td>{moment.utc(application.updated_at).local().format('MMMM Do, h:mm a')}</td>
      <td>
        {
          Object.keys(application.form_summary).length > 0
          && (
            <a
              className="font-weight-bold text-info text-center flex-auto"
              onClick={() => displayModal(application.id)}
            >
              <u>Progress</u>
            </a>
          )
        }
      </td>
    </tr>
  </>
)

export default ApplicationRow;
