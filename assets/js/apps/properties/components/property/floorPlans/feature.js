import React from "react";
import {Input, Button} from 'reactstrap';
import EditUnits from './editUnits';
import actions from "../../../actions";

class Feature extends React.Component {
  state = {feature: this.props.feature};

  componentWillReceiveProps(props) {
    this.setState({...this.state, feature: props.feature});
  }

  toggleEditUnits() {
    this.setState({...this.state, editUnits: !this.state.editUnits});
  }

  toggleEdit(shouldSave) {
    if (shouldSave) actions.saveFeature(this.state.feature);
    this.setState({editMode: !this.state.editMode});
  }

  change(e) {
    this.setState({feature: {...this.state.feature, [e.target.name]: e.target.value}});
  }

  deleteFeature() {
    if (confirm('Delete this feature?')) {
      actions.deleteFeature(this.state.feature);
    }
  }

  cancel() {
    if (!this.state.feature.id) return this.deleteFeature();
    this.setState({feature: this.props.feature, editMode: false});
  }

  render() {
    const {feature, editUnits} = this.state;
    const change = this.change.bind(this);
    const editMode = this.state.editMode || !feature.id;
    return (
      <tr className="link-row">
        <td className="align-middle">
          <a onClick={this.deleteFeature.bind(this)}>
            <i className="fas fa-times text-danger"/>
          </a>
        </td>
        <td>
          <Input value={feature.name} onChange={change} name="name" disabled={!editMode}/>
        </td>
        <td>
          <Input type="number" value={feature.price} onChange={change}
                 name="price"
                 disabled={!editMode}/>
        </td>
        <td>
          <div className="d-flex">
            <Button onClick={this.toggleEdit.bind(this, editMode)} color="info">
              {editMode ? 'Save' : 'Edit'}
            </Button>
            {editMode && <Button onClick={this.cancel.bind(this)} color="danger" className="ml-3">
              Cancel
            </Button>}
          </div>
        </td>
        {/*<td>*/}
          {/*<Button onClick={this.toggleEditUnits.bind(this)}>*/}
            {/*{feature.units.length} Units*/}
          {/*</Button>*/}
        {/*</td>*/}
        {/*{editUnits && <EditUnits feature={feature} toggle={this.toggleEditUnits.bind(this)}/>}*/}
      </tr>
    )
  }
}

export default Feature;