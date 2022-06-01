import React from "react";

class PetsVehicles extends React.Component {
  render() {
    const {lang} = this.props;
    return <ul className="list-unstyled height">
      <li className="listItemTitle">{lang.pets_vehicles}</li>
      {this.props.pets.map((pet) => {
        return <li className="listItemSidebar" key={pet._id}>
          <b> {pet.name}:</b> {pet.weight} lb {pet.type}, {pet.breed}
        </li>
      })}
      {this.props.vehicles.map((vehicle) => {
        return <li className="listItemSidebar" key={vehicle._id}>
          <b> {vehicle.color} {vehicle.make_model}. LP: {vehicle.license_plate}({vehicle.state})</b>
        </li>
      })}
    </ul>;
  }
}

export default PetsVehicles;