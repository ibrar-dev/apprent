import React from 'react';
import {Row, Col, Nav, NavItem, NavLink,Card} from 'reactstrap';


class TabbedBox extends React.Component {
  navigate(link) {
    this.props.onNavigate(link);
    this.props.onClick && this.props.onClick();
  }

  render() {
    const {links, children, active, header} = this.props;
    return <Row>
      <Col sm={2} className="pr-0">
        {header}
        <Nav style={{backgroundColor:"transparent", borderLeft:"none"}} activeStyle={{color: '#9eaab7'}} vertical className="vertical-nav" >
          {links.map(link => {
            return <NavItem key={link.id} active={active === link.id} style={ active === link.id ? {borderRight:"none", borderLeft:"none", backgroundColor:"#a8b5c3"}: {borderRight:"none", borderLeft:"none"}} >
              <NavLink onClick={this.navigate.bind(this, link)} style={ active === link.id ? {backgroundColor:"#a8b5c3"}: {}} className="d-flex align-items-center pr-0">
                {link.icon !== false && <div style={{width: 17, height: 15}} className="mr-1 d-flex">
                  {link.icon && <img src={link.icon} className='img-fluid' alt=""/>}
                </div>}
                <div className="w-100 nowrap pr-2">{link.label}</div>
              </NavLink>
            </NavItem>;
          })}
        </Nav>
      </Col>
      <Col sm={10} className="pl-0 d-flex flex-column">
        {children}

      </Col>
    </Row>;
  }
}

export default TabbedBox;