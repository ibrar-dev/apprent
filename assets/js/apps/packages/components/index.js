import React, {useEffect, useState} from "react";
import {connect} from "react-redux";
import {Nav, NavItem, NavLink,Card,CardBody, Button, Container, Row, Col} from "reactstrap";
import HomeWindow from './homeWindow';
import PackageWindow from './packageWindow';
import NewPackage from './newPackage';
import actions from "../actions";
import MultiPropertySelect from "../../../components/multiPropertySelect/index";
import {getCookie} from "../../../utils/cookies";

const key = {
  main: HomeWindow,
  lobby: PackageWindow,
  recipients: HomeWindow
};

const CustomNavLink = ({field, label, active, setTab}) => {
  return (
    <NavItem>
      <NavLink active={active === field} onClick={() => setTab(field)}>
        {label}
      </NavLink>
    </NavItem>
  )
}

const PackageApp = () => {
  const [tab, setTab] = useState('main');
  const [active, setActive] = useState('home');
  const [newPackage, setNewPackage] = useState(false);
  const [properties, setProperties] = useState([]);

  useEffect(() => {
    setProperties(getCookie("multiPropertySelect"))
  }, [])

  useEffect(() => {
    actions.fetchFilteredPackages(properties);
  }, [properties])

  const Window = key[tab];

  return (
    <div>
      <MultiPropertySelect
        className="flex-fill w-100"
        onChange={(p) => setProperties(p)}
      />

      <Card style={{paddingTop: "10px"}}>
        <Nav tabs className="pl-3">
          <div className="d-flex flex-fill justify-content-between">
            <div className="d-flex justify-content-start">
              <CustomNavLink field="main" label="Main" active={active} setTab={setTab} />
              <CustomNavLink field="lobby" label="Lobby" active={active} setTab={setTab} />
            </div>
            <h3 style = {{color:"#465e77", margin: "0px"}}> Package Activity </h3>
            <Button active={false} onClick={() => setNewPackage(!newPackage)} size="sm" color="success" style={{marginRight: "16px"}}>
              <i className="fa fa-plus-circle" />{' '}New Package
            </Button>
          </div>
        </Nav>
        <Card className="rounded-0 border-top-0 border-left-0 m-0 flex-auto" >
          <CardBody>
            <Window />
          </CardBody>
        </Card>
        {newPackage && <NewPackage toggle={() => setNewPackage(!newPackage)}/>}
      </Card>
    </div>
  )
}

export default connect(packages => {
    return (packages)
})(PackageApp)
