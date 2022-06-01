import React from 'react';
import {Popover} from 'reactstrap';

export default class extends React.Component {
  constructor(props) {
    super(props);
    this.toggle = this.toggle.bind(this);
  }

  toggle(e) {
    if (this.container && this.container.contains(e.target)) return;
    const {toggle, isOpen} = this.props;
    if (isOpen) {
      document.removeEventListener('click', this.toggle)
    } else {
      document.addEventListener('click', this.toggle);
    }
    toggle();
  }

  render() {
    const {toggle, children, ...props} = this.props;
    return <Popover {...props} toggle={this.toggle.bind(this)}>
      <div ref={(n) => this.container = n}>
        {children}
      </div>
    </Popover>
  }
}