import React from 'react';

class Header extends React.Component {
  state = {
    sortDir: 0,
    read: false
  };

  setSortDir() {
    const {sortDir} = this.state;
    const newSortDir = sortDir < 1 ? 1 : -1;
    this.setState({sortDir: newSortDir});
    return newSortDir;
  }
    sort() {
    const {sort, label} = this.props;
    if (!sort) return;
    const sortDir = this.setSortDir();
    if (typeof sort === 'function') {
      this.props.parent.setSortingFunc((a, b) => sort(a, b) * sortDir, label);
    }
    else {
      const func = (a, b) => {
        if (typeof a[sort] === 'string') {
          const first = (a[sort] || '').toUpperCase();
          const second = (b[sort] || '').toUpperCase();
          return (first < second ? -1 : 1) * sortDir;
        } else if (typeof a[sort] === 'number') {
          return (a[sort] - b[sort]) * sortDir;
        }
      };
      this.props.parent.setSortingFunc(func, label);
    }
  }

  render() {
    const {label, min, width, sort, className} = this.props;
    const {sortDir} = this.state;
    const arrow = ['down pt-1', 'double-arrow', 'up pt-1'][sortDir + 1];
    return <th onClick={this.sort.bind(this)}  className={"sticky align-middle nowrap " + (className || '')}
        style={{cursor: 'pointer', width: width || (min ? 1 : 'auto'), borderTop:"none"}}>
      <div className="d-flex justify-content-between">
        {label}
        {sort && <i className={`fas fa-caret-${arrow} ml-1`}/>}
      </div>
    </th>
  }
}

export default Header;
