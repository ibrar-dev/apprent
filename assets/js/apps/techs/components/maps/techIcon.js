import React from "react";

const techIconStyle = {
  background: 'yellow',
  border: '1px solid',
  padding: '3px 5px',
  whiteSpace: 'nowrap',
  borderRadius: 9
};

class TechIcon extends React.Component {
  render() {
    const {tech, color} = this.props;
    const style = tech.presence ? {...techIconStyle, background: '#bfe8ae'} : techIconStyle;
    return <div style={{...style, background: (color || style.background)}}>
      <b>{tech.name}</b>
    </div>;
  }
}

export default TechIcon;