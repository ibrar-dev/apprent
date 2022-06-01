import React from 'react';
import {connect} from 'react-redux';
import PersonForm from './personForm';
import actions from "../actions";
import Person from "../models/person";
import {Button} from "reactstrap";

class Occupants extends React.Component {
  state = {
    slideTo: 0,
  };

  addOccupant() {
    actions.addToCollection('occupants', new Person());
  }

  slideTo(index) {
    this.setState({...this.state, slideTo: index})
  }

  deleteOccupant() {
    const occ = this.props.application.occupants.models[this.state.slideTo];
    actions.deleteCollection('occupants', occ._id);
    this.slideTo(this.state.slideTo - 1)
  }

  render() {
    const {occupants} = this.props.application;
    const {language, property} = this.props;
    const {slideTo} = this.state;
    return <div className="card">
      <div className="card-header">
        {language.occupants}
      </div>
      <div className="card-body">
        {!property.accepting_applications && <div className="d-flex justify-content-center" style={{position: "fixed",
          width: "100%",
          height: "100%",
          zIndex: 99999,
          backgroundColor: "rgba(0,0,0,0.9)",
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          opacity: .5}}>
          <div className="overlay-text">
            Unfortunately we are not accepting applications at this time.
          </div>
          {property.accepting_tours && <a style={{marginTop: 55}} className="overlay-text overlay-button btn btn-round" href={`/showings/${property && property.code}`}>
            Schedule a Tour
          </a>}
        </div>}
        <button className="btn rounded-circle add-person" style={{backgroundColor: "#ccecd1"}}
                onClick={this.addOccupant.bind(this)}>
          <i className="fas fa-plus text-success"/>
        </button>
        {slideTo > 0 &&
        <button className="btn btn-danger rounded-circle delete-person" onClick={this.deleteOccupant.bind(this)}>
          <i className="fas fa-trash"/>
        </button>}
        <div className="person-slider">
          <div className="nav-group border-0">
            {occupants.map((o, i) => <Button outline={!(slideTo === i)}
                                             key={o._id}
                                             onClick={this.slideTo.bind(this, i)}>
              {o.full_name || `Occupant #${i + 1}`}</Button>
            )}
            {occupants.length < 5 && <div className="trick"/>}
          </div>
          <div className="slider-body"
               style={{width: `${occupants.length}00%`, marginLeft: `-${slideTo}00%`}}>
            {occupants.map((o, i) => <PersonForm key={o._id}
                                                 person={o}
                                                 total={occupants.length}
                                                 language={language}
                                                 index={i}/>)}
          </div>
        </div>
      </div>
    </div>;
  }
}

export default connect(({application, language, property}) => {
  return {application, language, property};
})(Occupants);
