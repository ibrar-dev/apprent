import React from 'react';
import {Row, Col, Nav, NavItem, NavLink} from 'reactstrap';

class TabbedBox extends React.Component {
  navigate(link) {
    this.props.onNavigate(link);
    this.props.onClick && this.props.onClick();
  }

  render() {
    const {links, children, active, header, footer, hidden} = this.props;
    return <Row className="m-0">
      {!hidden && <Col sm={2} className="px-0">
        {header}
        <Nav vertical className="vertical-nav">
          {links.map(link => {
            return <NavItem className="w-100" key={link.id} active={active === link.id}>
              <NavLink onClick={this.navigate.bind(this, link)} className="d-flex align-items-center pr-0">
                {link.icon !== false && <div style={{width: 17, height: 15}} className="mr-1 d-flex">
                  {link.icon && <img src={link.icon} className='img-fluid' alt=""/>}
                </div>}
                <div className="w-100 nowrap pr-2">{link.label}</div>
              </NavLink>
            </NavItem>;
          })}
        </Nav>
        {footer}
      </Col>}
      <Col className="px-0 d-flex flex-column">
        {children}
      </Col>
    </Row>;
  }
}

export default TabbedBox;