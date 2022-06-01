import React from 'react';

class Group extends React.Component {
  render() {
    const {name, links, alerts} = this.props;
    return <React.Fragment>
      {name !== 'Dashboard' && <li className="nav-title">{name}</li>}
      {links.map(link => {
        return <li key={link.href} className="nav-item">
          <a className="nav-link" href={`/${link.href}`}>
            <i className={link.icon}/>
            {link.label}
            {link.href === "alerts" && alerts >= 1 && <span className="badge badge-primary">{" "}{alerts}</span>}
          </a>
        </li>
      })}
    </React.Fragment>
  }
}

export default Group;