import React from 'react';

class FancyCheck extends React.Component {
  constructor(props) {
    super(props);
    this.checkbox = React.createRef();
  }

  componentDidUpdate(prevProps, prevState, snapshot) {
    this.checkbox.current.indeterminate = this.props.indeterminate && !this.props.checked;
  }

  render() {
    const {name, checked, onChange, value, inline, style, disabled, label} = this.props;
    return <label className={`fancy-check${(inline) ? '' : ' d-block'}`}
                  onClick={(e) => e.stopPropagation()} style={style}>
      <div className="d-flex align-items-center">
        <input type="checkbox"
               disabled={disabled}
               name={name}
               id={name}
               ref={this.checkbox}
               value={value || 'on'}
               checked={checked}
               onChange={onChange}/>
        <div className="checkbox"/>
        <div className="wipe"/>
        {label && <div className="ml-2">{label}</div> }
      </div>
    </label>
  }
}

export default FancyCheck;