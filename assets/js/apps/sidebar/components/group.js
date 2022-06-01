import React from "react";

const Group = ({name, links, alerts}) => (
  <div style={{paddingBottom: 20}}>
    {name !== "Dashboard" && <li className="nav-title">{name}</li>}
    {
      links.map((link) => (
        link.label
          ? (
            <li
              key={link.href}
              className="nav-item"
            >
              <a className="nav-link" href={`/${link.href}`}>
                <i className={link.icon} />
                {link.label}
                {link.href === "alerts" && alerts >= 1 && (
                <span className="badge" style={{backgroundColor: '#38a250'}}>
                  {" "}
                  {alerts}
                </span>
                )}
              </a>
            </li>
          )
          : null
      ))
    }
  </div>
);

export default Group;
