import React from 'react';

class CustomSelect extends React.Component {
  constructor(props) {
    super(props);
    this.state = {};
    this.menuRef = React.createRef();
  }

  componentDidUpdate(prevProps, prevState, snapshot) {
    const {value, options} = this.props;
    const index = options.indexOf(value);
    this.menuRef.current.scrollTop = this.menuRef.current.children[0].children[index].offsetTop;
  }

  toggle() {
    this.setState({open: !this.state.open});
  }

  onSelect(value) {
    const {onSelect} = this.props;
    onSelect(value);
    this.toggle();
  }

  render() {
    const {open} = this.state;
    const {value, options, yearMode} = this.props;
    return <div onClick={this.toggle.bind(this)} className="position-relative border react-dates-label">
      <div className="d-flex align-items-center justify-content-between">
        <div className="mr-3">{value}</div>
        <i className={`fas fa-caret-${open ? 'up text-muted' : 'down'}`} style={{marginTop: 2}}/>
      </div>
      <div className={`position-absolute border bg-white react-dates-date-select${open ? '' : ' d-none'}`} ref={this.menuRef}>
        <ul className="list-unstyled m-0">
          {options.map((label, index) => {
            const val = yearMode ? label : index;
            return <li key={index} className="p-0">
              <a className={`d-block p-2 ${value === label ? 'bg-info text-white' : ''}`}
                 onClick={this.onSelect.bind(this, val)}>{label}</a>
            </li>
          })}
        </ul>
      </div>
    </div>
  }
}

export default CustomSelect;