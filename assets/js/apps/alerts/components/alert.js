import React, {Component} from 'react';
import icons from "../../../components/flatIcons";
import moment from "moment";
import canEdit from "../../../components/canEdit";
import actions from "../actions";

function downloadAtt(url) {
  return <a href={url} target="_blank">
    <i className="fas fa-download" />
  </a>
}
class Alert extends Component {
  state = {};

  classToDisplay(flag) {
    switch (flag) {
      case 5:
        return 'table-danger';
      case 4:
        return 'table-warning';
      case 3:
        return 'table-primary';
      default:
        return '';
    }
  }

  updateRead(alert) {
    actions.updateAlert(alert);
  }

  deleteAlert(alertId) {
    actions.deleteAlert(alertId)
  }

  render() {
    const {alert, activeAlertID, setActiveAlert} = this.props;
    return <tr onClick={setActiveAlert.bind(this, alert)} className={`${activeAlertID === alert.id ? 'table-active' : ''} ${this.classToDisplay(alert.flag)}`}>
      <td onClick={this.updateRead.bind(this, alert)}><img className="img-fluid" style={{maxWidth: 25}} src={alert.read ? icons.checked : icons.cancel} alt=""/></td>
      <td>{alert.flag}</td>
      <td>{alert.sender}</td>
      <td>{alert.note}</td>
      <td>
        {alert.attachment_id ? downloadAtt(alert.attachment_url.url) : ""}
      </td>
      <td>{moment.utc(alert.inserted_at).format("M/D/YY h:mm")}</td>
      {canEdit(["Super Admin", "Regional"]) && <td style={{cursor: 'pointer'}} onClick={e => e.stopPropagation()}><img onClick={this.deleteAlert.bind(this, alert.id)} src={icons.trash} className='img-fluid' style={{maxWidth: 20, maxHeight: 20}} alt=""/></td>}
    </tr>
  }
}

export default Alert;