import React from 'react';
import {connect} from 'react-redux';
import actions from '../actions';
import Pet from '../models/pet';
import utils from './utils';

class PetForm extends React.Component {
  editField(e) {
    actions.editCollection('pets', this.props.index, e.target.name, e.target.value);
  }

  deletePet() {
    actions.deleteCollection('pets', this.props.pet._id);
  }

  render() {
    const userField = utils.userField.bind(this, this.props.pet);
    const {lang} = this.props;
    return <div className="card">
      <div className="card-header">
        {lang.pet} #{this.props.index + 1}
        <a className="delete-button" onClick={this.deletePet.bind(this)}>
          <i className="fas fa-trash"/>
        </a>
      </div>
      <div className="card-body pt-0">
        {userField('name', lang.name)}
        {userField('type', lang.type)}
        {userField('breed', lang.breed)}
        {userField('weight', lang.weight)}
      </div>
    </div>
  }
}

class Pets extends React.Component {

  addPet() {
    actions.addToCollection('pets', new Pet());
  }

  render() {
    const {pets} = this.props.application;
    const {lang} =this.props;
    return <div>
      {pets.map((pet, index) => {
        return <PetForm key={pet._id} lang={lang} index={index} pet={pet}/>;
      })}
      { pets.length < 2 && <div className="add-button" onClick={this.addPet.bind(this)}>
        <button>
          <i className="fas fa-plus"/>
        </button>
        {lang.add_pet}
      </div>}
    </div>;

  }
}

export default connect((s) => {
  return {application: s.application, lang: s.language}
})(Pets);