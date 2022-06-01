import React from 'react';

// class AvailableUnit extends React.Component {

const AvailableUnit = ({unit}) => {

  // render() {
  //   const {unit} = this.props;
    return (
      <tr  className="link-row"  >
        <td className="align-middle">
          {unit.property_name}
        </td>
        <td className="align-middle">
          {unit.number}
        </td>
        <td className="align-middle">
          {unit.status}
        </td>
      </tr>
    )
}

export default AvailableUnit;