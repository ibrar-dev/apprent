import React from 'react';
import {Button, ButtonGroup, Col, Row} from 'reactstrap';
import posed from 'react-pose';
import actions from "../actions";

const Sidebar = posed.ul({
  open: {
    x: '0%',
    delayChildren: 100,
    staggerChildren: 50, width: '100%', height: "350px"
  },
  closed: {x: '0%', delay: 300, width: 0, height: 0}
});

const Item = posed.li({
  open: {y: 0, opacity: 1},
  closed: {y: 20, opacity: 0}
});

class Cart extends React.PureComponent {

  changeQuantity(type, cart) {
    const stock_id = window.location.pathname.match(/materials\/(\d+)/)[1];
    if (type === 'plus') {
      actions.addItemToCart({id: cart.item[0].material_id}, stock_id, this.props.shop_user.id);
    } else {
      actions.removeItemFromCart(cart.item.pop().id, stock_id, this.props.shop_user.id);
    }
    actions.resetTime();
  }

  render() {
    const {cart, isOpen, onPoseComplete, changeQuantity} = this.props;
    return <Sidebar pose={isOpen ? 'open' : 'closed'} onPoseComplete={!isOpen && onPoseComplete} style={{
      width: "100%",
      background: "white",
      padding: "0px",
      display: "flex",
      flexDirection: "column",
      listStyle: "none",
      margin: "0",
      top: "0",
      bottom: "0",
      overflowY: "scroll"
    }}>
      {cart.map(x => {
        return <Item key={x.item[0].id} style={{
          padding: "5px",
          backgroundColor: "#fbfbfb",
          borderColor: "#f4f6f9",
          color: "#565656",
          marginTop: "16px",
          transformOriginY: "0%",
          width: "98%",
          marginLeft: "1%",
          boxShadow: "1px 1px 5px 0px rgba(128,128,128,0.28)"
        }}>
          <Col>
            <Row>
              <p style={{fontSize: "95%"}}>{x.item[0].name}</p>
            </Row>
            <Row>
              <Col style={{padding: "0px"}}>
                <ButtonGroup className="d-flex " size="sm">
                  <Button block outline color="primary" disabled={x.count === 0}
                          onClick={x.count > 0 ? changeQuantity.bind(this, "minus", x) : null}
                          style={{margin: "0px", backgroundColor: "#4fa4ff", borderColor: "transparent"}}>
                    <i className="fas fa-minus"/></Button>
                  <Button block outline disabled style={{
                    margin: "0px",
                    color: "#565656",
                    fontWeight: "bold"
                  }}>{x.count} / {x.item[0].inventory} </Button>
                  <Button block outline color="primary" disabled={x.count === x.item[0].inventory}
                          onClick={x.count < x.item[0].inventory ? changeQuantity.bind(this, "plus", x) : null}
                          style={{margin: "0px", backgroundColor: "#4fa4ff", borderColor: "transparent"}}>
                    <i className="fas fa-plus"/></Button>
                </ButtonGroup>
              </Col>
            </Row>
          </Col>
        </Item>
      })}
    </Sidebar>

  }
}

export default Cart;