import React from "react";

const techIconStyle = {
  borderRadius: '50%',
  padding: '.2rem .25rem',
  marginRight: '.5rem',
};

const hoverStyle = {
  border: '2px solid #465e77',
  boxShadow: '0 0 3px 3px rgb(70, 94, 119)'
};

class TechIcon extends React.Component {
  render() {
    const {tech, color, selected} = this.props;
    const style = selected ? {...techIconStyle, ...hoverStyle} : techIconStyle;
    return <div className={`btn btn-${color || 'danger'}`} style={style}>
      <b>{tech.name.split(' ').map(n => n[0]).join('').toUpperCase()}</b>
    </div>;
  }
}

export default TechIcon;