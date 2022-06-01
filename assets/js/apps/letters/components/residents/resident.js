import React from 'react';
import {connect} from 'react-redux';
import FancyCheck from "../../../../components/fancyCheck";
import {toCurr} from "../../../../utils";
import actions from "../../actions";

class Resident extends React.Component {
  state = {selected: false};

  toggleSelected() {
    actions.selectResident(this.props.resident.id);
  }

  togglePreview() {
    this.setState({preview: !this.state.preview})
  }

  render() {
    const {resident, selectedResidents, letter} = this.props;
    const selected = selectedResidents.indexOf(resident.id) > -1;
    const {preview} = this.state;
    return <>
      <tr className={`${selected ? 'table-success' : ''}`}>
        <td className="align-middle">
          <FancyCheck checked={selected} onChange={this.toggleSelected.bind(this)}/>
        </td>
        <td className="align-middle">
          <a className="text-decoration-none" href={`/tenants/${resident.id}`} target="_blank">
            {resident.first_name} {resident.last_name}
          </a>
        </td>
        <td className="align-middle">{resident.unit}</td>
        <td className={`align-middle text-${resident.balance && resident.balance > 0 ? 'danger' : 'success'} mr-3`}>
          {toCurr(resident.balance)}
        </td>
        <td className="align-middle pl-4">
          <i
            className={`fas fa-${resident.future ? 'house-damage' : 'home'} text-${resident.past ? 'danger' : 'success'}`}/>
        </td>
        <td className="align-middle">{resident.start_date} - {resident.end_date}</td>
        <td className="align-middle pl-4">
          <a onClick={letter ? this.togglePreview.bind(this) : null}>
            <i className={`fas fa-2x fa-${preview ? 'minus-circle' : 'eye'}${!preview && !letter ? '-slash' : ''}`}/>
          </a>
        </td>
      </tr>
      {preview && <tr>
        <td colSpan={7}>
          <iframe src={`/api/letter_templates/${letter}?tenant_id=${resident.id}`} height={550} width="100%"/>
        </td>
      </tr>}
    </>;
  }
}

export default connect(({selectedResidents}) => {
  return {selectedResidents};
})(Resident);