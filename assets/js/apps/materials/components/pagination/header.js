import React from 'react';

class Header extends React.Component {

  reverseOrder = false;

  sort() {
    const {sort, label} = this.props;
    if (!sort) return;
    const factor = this.reverseOrder ? -1 : 1;
    if (typeof sort === 'function') {
      this.props.parent.setSortingFunc((a, b) => sort(a, b) * factor, label);
    } else {
      const func = (a, b) => {
        if (typeof a[sort] === 'string') {
          const first = (a[sort] || '').toUpperCase();
          const second = (b[sort] || '').toUpperCase();
          return (first < second ? -1 : 1) * factor;
        } else if (typeof a[sort] === 'number') {
          return (a[sort] - b[sort]) * factor;
        }
      };
      this.props.parent.setSortingFunc(func, label);
    }
    this.reverseOrder = !this.reverseOrder;
  }

  render() {
    const {label} = this.props;
    return <th style={{ borderTopWidth:"0px", borderBottomWidth:"1px", fontSize:"15px"}}>
      <a onClick={this.sort.bind(this)}>{label}</a>
    </th>;
  }
}

export default Header;