import React from 'react';
import {Input, Button} from 'reactstrap';
import actions from '../../../actions';

class Pet extends React.Component {
  state = {...this.props.pet};

  toggleMode() {
    this.setState({editMode: !this.state.editMode});
  }

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  save() {
    actions.updatePet(this.state).then(() => {
      this.setState({editMode: false});
    })
  }

  toggleActive() {
    const {pet} = this.props;
    actions.updatePet({id: pet.id, active: !pet.active}).then(() => {
      this.setState({editMode: false});
    })
  }

  render() {
    const {pet} = this.props;
    const {editMode, name, breed, weight, type} = this.state;
    const change = this.change.bind(this);
    if (editMode) {
      return <tr>
        <td>
          <Input value={type} name="type" onChange={change}/>
        </td>
        <td>
          <Input value={breed} name="breed" onChange={change}/>
        </td>
        <td>
          <Input value={name} name="name" onChange={change}/>
        </td>
        <td>
          <Input value={weight} name="weight" onChange={change}/>
        </td>
        <td>
          <Button color="success" onClick={this.save.bind(this)}>
            Save
          </Button>
        </td>
        <td/>
      </tr>;
    }
    return <tr className={pet.active ? '' : 'text-muted'}>
      <td className="align-middle">
        {pet.type}
      </td>
      <td className="align-middle">
        {pet.breed}
      </td>
      <td className="align-middle">
        {pet.name}
      </td>
      <td className="align-middle">
        {pet.weight} lb
      </td>
      <td className="align-middle">
        <Button color="info" onClick={this.toggleMode.bind(this)}>
          Edit
        </Button>
      </td>
      <td>
        <Button className="nowrap" color="danger" onClick={this.toggleActive.bind(this)}>
          Make {pet.active ? 'Inactive' : 'Active'}
        </Button>
      </td>
    </tr>;
  }
}

export default Pet;