import React, {useState} from "react";
import {connect} from "react-redux";
import {data, permissions} from "../links";
import Group from "./group";
import Toolbar from "./toolbar";
import Logo from "./logo";
import SearchBar from "./searchBar";

const Sidebar = ({role, alerts}) => {
  const [filter, setFilter] = useState("");

  const filterRegex = new RegExp(filter, "i");
  const links = data([role]);

  const linksToDisplay = (group) => (
    links[group].filter((i) => filterRegex.test(i.label) || filterRegex.test(i.tags))
  );

  return (
    <nav className="sidebar-nav" style={{paddingTop: 0}}>
      <Logo />
      <SearchBar
        onChange={(v) => setFilter(v.target.value)}
        placeholder="Quick Search"
        value={filter}
      />

      {permissions.length > 1 && <Toolbar />}
      <ul className="nav" style={{minHeight: 100, paddingBottom: 45}}>
        {
          Object.keys(links).map((g) => (
            linksToDisplay(g).length
              ? (
                <Group
                  key={g}
                  name={g}
                  links={linksToDisplay(g)}
                  alerts={alerts}
                />
              )
              : null
          ))
        }
      </ul>
    </nav>
  );
};

const mapStateToProps = ({role, alerts}) => ({role, alerts});
export default connect(mapStateToProps)(Sidebar);
