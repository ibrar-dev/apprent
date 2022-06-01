import React from 'react';
import {connect} from 'react-redux';
import {Modal, ModalHeader, ModalBody, Button} from 'reactstrap';
import Select from '../../../../../components/select';
import actions from '../../../actions';

class EditUnits extends React.Component {
  constructor(props) {
    super(props)
    if (props.feature.units && props.feature.units.length) {
      this.state = {selectedUnits: props.feature.units.map(u => u.id)}
    } else {
      this.state = {selectedUnits: []}
    }
  }

  changeUnits({target: {value: selectedUnits}}) {
    this.setState({...this.state, selectedUnits});
  }

  submit() {
    const {feature, toggle, floorPlan} = this.props;
    const {selectedUnits} = this.state;
    const func = floorPlan ? 'updateFloorPlan' : 'updateFeature';
    actions[func]({...feature, unit_ids: selectedUnits}).then(toggle);
  }

  render() {
    const {toggle, feature, units, floorPlan} = this.props;
    const {selectedUnits} = this.state;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>
        Units With {floorPlan ? 'Floor Plan' : 'Feature'}: {feature.name}
      </ModalHeader>
      <ModalBody>
        <Select value={selectedUnits}
                multi
                closeOnSelect={false}
                matchProp="label"
                onChange={this.changeUnits.bind(this)}
                options={units}
        />
        <Button onClick={this.submit.bind(this)} className="mt-3 btn-block" color="success">
          Save
        </Button>
      </ModalBody>
    </Modal>
  }
}

export default connect(({units, property}) => {
  return {units: units.reduce((acc, u) => {
      if (u.property_id === property.id) acc.push({value: u.id, label: u.number});
      return acc;
    }, []).sort((a, b) => a.label > b.label ? 1 : -1)};
})(EditUnits);