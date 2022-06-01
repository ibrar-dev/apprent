import React from 'react';
import {Container, Col, Row} from 'reactstrap';
import posed from 'react-pose';
import actions from "../actions";
import moment from "moment/moment";
import Checkbox from '../../../components/fancyCheck';

const Sidebar = posed.ul({
  open: {
    x: '0%',
    delayChildren: 100,
    staggerChildren: 50, width: '100%', height: "400px"
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

  addToItemIDs(id) {
    let itemsArray = this.state.item_ids;
    itemsArray.includes(id) ? itemsArray.splice(itemsArray.indexOf(id), 1) : itemsArray.push(id);
    this.setState({item_ids: itemsArray});
  }

  render() {
    const {tool, isOpen, item_ids, onPoseComplete, addToItemIDs} = this.props;
    return <Sidebar pose={isOpen ? 'open' : 'closed'} onPoseComplete={!isOpen && onPoseComplete} style={{
      width: "0%",
      height: "0px",
      background: "white",
      padding: "0px",
      display: "flex",
      overflowX: "hidden",
      flexDirection: "column",
      listStyle: "none",
      margin: "0",
      top: "0",
      bottom: "0",
      overflowY: "scroll"
    }}>
      {tool.items.map(x => {
        return <Item key={x.id} style={{
          padding: "5px", backgroundColor: "#fbfbfb", width: "98%", marginLeft: "1%", marginTop: "16px",
          borderColor: "#f4f6f9", color: "#565656",
          boxShadow: "1px 1px 5px 0px rgba(128,128,128,0.28)"
        }} onClick={addToItemIDs.bind(this, x.id)}>
          <Row>
            <Container>
              <Row>
                <Col xs="9">
                  <p style={{fontSize: "80%"}}>{x.material}</p>
                </Col>
                <Col xs="3" className="d-flex align-items-end flex-column">
                  <Checkbox style={{borderColor: "#475f78"}} checked={item_ids.includes(x.id)}
                            onChange={addToItemIDs.bind(this, x.id)} color={`primary`}/>
                </Col>
              </Row>
              <Row className="d-flex justify-content-end">
                <small style={{
                  fontSize: "10px",
                  marginRight: "15px",
                  marginTop: "8px",
                  color: "#969696"
                }}>{moment.utc(x.date).local().fromNow()}</small>
              </Row>
            </Container>
          </Row>
        </Item>
      })}
    </Sidebar>

  }
}

export default Cart;