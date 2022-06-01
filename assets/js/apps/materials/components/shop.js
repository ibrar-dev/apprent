import React from 'react';
import {withRouter} from 'react-router';
import Pagination from './pagination';
import Countdown from './countdown';
import actions from '../actions';
import Items from "./items";
import {connect} from "react-redux";
import QrReader from 'react-qr-reader';
import Localization from "../../../components/localization/index.js";
import icons from '../../../components/flatIcons';
import canEdit from '../../../components/canEdit';
import {PoseGroup} from 'react-pose';
import Cart from './cart'
import Tool from './tool'
import {
  Nav, NavItem, NavLink, Button, InputGroup, InputGroupAddon, Card, CardBody, Collapse,
  CardHeader, CardFooter, Modal, ModalBody, ModalHeader, Container, CardTitle, CardSubtitle, CardText, Input, Col,
  Row, ListGroup, ListGroupItem, Badge
} from 'reactstrap';

const headers = (localization) => {
  return [
    {label: '', sort: 'type'},
    {label: localization.name, sort: 'name'},
    {label: localization.available, sort: 'available'},
    {label: '', sort: ''}
  ];
};

class Shop extends React.Component {
  state = {
    filterVal: '',
    cart: [],
    checkout: false,
    activeTab: "cart",
    item_ids: [],
    cameraReader: false,
    language: Localization('en_US'),
    showCart: true
  };

  componentWillMount() {
    const stock_id = window.location.pathname.match(/materials\/(\d+)/)[1];
    actions.checkIfLoggedIn(stock_id);
  }

  update(e) {
    this.setState({...this.state, password: e.target.value});
    actions.resetTime();
  }

  enter() {
    const stock_id = window.location.pathname.match(/materials\/(\d+)/)[1];
    actions.shopVerify({password: this.state.password}, stock_id);
  }

  changeFilter(e) {
    this.setState({...this.state, filterVal: e.target.value});
    actions.resetTime();
  }

  _filters() {
    const {filterVal} = this.state;
    return <Input value={filterVal} onChange={this.changeFilter.bind(this)} style={{width: "100%"}}/>
  }

  checkOut() {
    const stock_id = window.location.pathname.match(/materials\/(\d+)/)[1];
    actions.shopCheckout(stock_id, this.props.shop_user.id);
    this.setState({...this.state, checkConfirm: !this.state.checkConfirm});
    setTimeout(this.signOut.bind(this), 5000);
  }

  filtered() {
    const {filterVal} = this.state;
    const {shop_materials} = this.props;
    const regex = new RegExp(filterVal, 'i');
    return shop_materials.filter(m => {
      return (m.name && m.name.match(regex));
    });
  }

  signOut() {
    const stock_id = window.location.pathname.match(/materials\/(\d+)/)[1];
    actions.signOutOfShop(stock_id);
    this.setState({...this.state, checkout: false, checkConfirm: false});
  }

  cart(cart) {
    let newCart = [];
    let found = false;
    cart.map(x => {
      newCart.find((y, i) => {
        if (y.item[0].material_id === x.material_id) {
          newCart[i].count++;
          newCart[i].item.push(x);
          found = true;
        }
      });
      found && newCart[0] ? newCart : newCart.push({item: [x], count: 1});
      found = false;
    });
    return newCart;
  }

  toggle(type) {
    this.setState({...this.state, activeTab: type});
    actions.resetTime();
  }

  toggleCheckout() {
    this.setState({...this.state, checkout: !this.state.checkout});
  }

  toggleReturn() {
    this.setState({...this.state, returns: !this.state.returns, returnConfirm: false});
  }

  changeQuantity(type, cart) {
    const stock_id = window.location.pathname.match(/materials\/(\d+)/)[1];
    if (type === 'plus') {
      actions.addItemToCart({id: cart.item[0].material_id}, stock_id, this.props.shop_user.id);
    } else {
      actions.removeItemFromCart(cart.item.pop().id, stock_id, this.props.shop_user.id);
    }
    actions.resetTime();
  }

  returnItems() {
    const stock_id = window.location.pathname.match(/materials\/(\d+)/)[1];
    this.setState({item_ids: [], returnConfirm: !this.state.returnConfirm});
    this.state.item_ids.map(x => {
      actions.returnItems({item_id: x, stock_id: stock_id})
    });
  }

  addToItemIDs(id) {
    let itemsArray = this.state.item_ids;
    itemsArray.includes(id) ? itemsArray.splice(itemsArray.indexOf(id), 1) : itemsArray.push(id);
    this.setState({item_ids: itemsArray});
  }

  toggleCamera() {
    this.setState({...this.state, cameraReader: !this.state.cameraReader})
  }

  handleScan(data) {
    if (data) {
      const data1 = JSON.parse(data);
      this.setState({
        ...this.state,
        password: data1.identifier,
        language: Localization(data1.language)
      }, () => this.enter());
    }
  }

  handleError(error) {
    this.setState({...this.state, error: error});
  }

  selectAll() {
    const items_array = this.state.selectAll ? [] : this.props.tool_box[0].items.map(x => x.id);
    this.setState({item_ids: items_array, selectAll: !this.state.selectAll});
  }

  clearCart() {
    const stock_id = window.location.pathname.match(/materials\/(\d+)/)[1];
    actions.clearCart(stock_id);
  }

  showCart() {
    this.setState({...this.state, showCart: !this.state.showCart})
  }

  render() {
    const {shop_user, shop_cart, tool_box, stock} = this.props;
    const {item_ids, cameraReader, checkout, activeTab, checkConfirm, returns, returnConfirm, language, showCart} = this.state;
    return <React.Fragment>
      {!shop_user.name ?
        <Container style={{height: "700px", width: "500px"}} className="d-flex align-items-center">
          <Card body className="text-center align-items-center"
                style={{height: `${!cameraReader ? '200px' : '650px'}`, width: "260px"}}>
            <CardTitle>Shop Sign-in</CardTitle>
            <CardText> Enter Identifier </CardText>
            {!cameraReader && <React.Fragment>
              {canEdit(["Super Admin"]) ?
                <div>
                  <InputGroup>
                    <Input onChange={this.update.bind(this)}/>
                    <InputGroupAddon addonType="append"><Button onClick={this.toggleCamera.bind(this)} outline
                                                                color="secondary"><i
                      className="fas fa-camera"/></Button></InputGroupAddon>
                  </InputGroup>
                  <Button color="success" onClick={this.enter.bind(this)}
                          style={{width: "100px", marginTop: "20px"}}> Sign In </Button></div> :
                <Button onClick={this.toggleCamera.bind(this)} outline color="secondary"
                        style={{height: "60px", width: "60px"}}><i className="fas fa-camera fa-2x"/></Button>}
            </React.Fragment>}
            {cameraReader && <React.Fragment>
              <QrReader resolution={1200} onError={this.handleError.bind(this)} style={{width: 450, height: 450}}
                        onScan={this.handleScan.bind(this)}/>
              {/*{error && <span>{error}</span>}*/}
              <Button color="danger" onClick={this.toggleCamera.bind(this)}
                      style={{width: "100px", marginTop: "20px"}}>Cancel</Button>
            </React.Fragment>}
          </Card>
        </Container> :
        <div className="container-fluid" style={{backgroundColor: "white", padding: "0px"}}>
          <CardHeader style={{color: "#f2f6ff", backgroundColor: "white"}}>
            <Row>
              <Col xs="3" className="d-flex justify-content-start align-items-center">
                <img src={shop_user.image ? shop_user.image : icons.noUserImage} style={{
                  borderRadius: "50%",
                  marginLeft: "8px",
                  marginRight: "5px",
                  boxShadow: "1px 1px 5px 0px rgba(128,128,128,0.28)"
                }} alt="Smiley face" height="50" width="50"/>
                <div>
                  <h5 style={{color: "#475f78", marginBottom: "0px"}}>{language["welcome"]},</h5>
                  <h5 style={{color: "#475f78"}}>{shop_user.name}</h5>
                </div>
              </Col>
              <Col xs="6" className="d-flex justify-content-center align-items-center">
                <h3 style={{color: "#475f78", fontWeight: "bold"}}>{stock && stock.name.toLocaleUpperCase()}</h3>
              </Col>
              <Col xs="3" className="d-flex justify-content-end align-items-center">
                <small className="text-muted">
                  {language['signedOut']} <Countdown onComplete={this.signOut.bind(this)}/>
                </small>
                <img style={{marginLeft: "5px", cursor: "pointer"}}
                     src={icons.sign_out}
                     alt=""
                     onClick={this.signOut.bind(this)} height="30px"/>
              </Col>
            </Row>
          </CardHeader>
          <Row>
            <Col sm="9" style={{paddingRight: "0px"}}>
              <Pagination
                title={language['shopItems']}
                collection={this.filtered()}
                headers={headers(language)}
                component={Items}
                filters={this._filters()}
                field="item"
                hover={true}
              />
            </Col>
            <Col sm="3" style={{paddingLeft: "0px", paddingTop: "12px"}}>
              <Card style={{position: "fixed", width: "21%"}}>
                <Nav tabs style={{marginLeft: "-1px"}}>
                  <NavItem>
                    <NavLink
                      className={activeTab === 'cart' ? 'active' : ''}
                      onClick={() => {
                        this.toggle('cart');
                      }}
                      style={activeTab === 'cart' ? {
                        fontSize: "25px",
                        fontWeight: 'bold',
                        color: "#475f78",
                        opacity: 1
                      } : {fontSize: "25px", fontWeight: 'bold', color: "#475f78", opacity: 0.5}}>
                      <img src={icons.shoppingCart} alt="Smiley face" height={activeTab === 'cart' ? "30" : "20"}
                           width={activeTab === 'cart' ? "30" : "20"}/>
                      {activeTab === 'tool' &&
                      <Badge size="sm" color="danger" style={{height: "20px", fontSize: "14px", marginLeft: "2px"}}
                             pill>{shop_cart.length}</Badge>}
                    </NavLink>
                  </NavItem>
                  <NavItem>
                    <NavLink
                      className={activeTab === 'tool' ? 'active' : ''}
                      onClick={() => {
                        this.toggle('tool');
                      }}
                      style={activeTab === 'tool' ? {
                        fontSize: "25px",
                        fontWeight: 'bold',
                        color: "#475f78",
                        opacity: 1
                      } : {fontSize: "25px", fontWeight: 'bold', color: "#475f78", opacity: 0.5}}>
                      <img src={icons.toolbox} alt="Smiley face" height={activeTab === 'tool' ? "30" : "20"}
                           width={activeTab === 'tool' ? "30" : "20"}/>
                      {activeTab === 'cart' &&
                      <Badge size="sm" color="danger" style={{height: "20px", fontSize: "14px", marginLeft: "3px"}}
                             pill>{tool_box[0] && tool_box[0].items.length}</Badge>}
                    </NavLink>
                  </NavItem>
                </Nav>
                <CardBody style={{}}>
                  <CardSubtitle style={{marginBottom: "10px", color: "#6990b9"}}> You
                    have {activeTab === "cart" ? shop_cart.length : (tool_box[0] && tool_box[0].items.length) || 0} item(s)
                    in
                    your {activeTab === 'cart' && stock && stock.name} {activeTab === "cart" ? "cart" : "tool box"}</CardSubtitle>
                  {<small style={{color: "#007bff", cursor: "pointer"}}
                          onClick={activeTab === "tool" ? this.selectAll.bind(this) : this.clearCart.bind(this)}>{activeTab === "tool" ? tool_box[0] && tool_box[0].items.length !== 0 && "select all" : shop_cart.length !== 0 && "clear all"}</small>}
                  <PoseGroup>
                    {showCart && <Cart key="cart" cart={this.cart(shop_cart)} isOpen={activeTab === "cart"}
                                       onPoseComplete={this.showCart.bind(this)}
                                       changeQuantity={this.changeQuantity.bind(this)}/>}
                    {!showCart && tool_box[0] &&
                    <Tool key="tool" tool={tool_box[0]} item_ids={item_ids} isOpen={activeTab === "tool"}
                          onPoseComplete={this.showCart.bind(this)} addToItemIDs={this.addToItemIDs.bind(this)}/>}
                  </PoseGroup>
                </CardBody>
                <Collapse
                  isOpen={(activeTab === "cart" && shop_cart.length !== 0) || (activeTab === "tool" && tool_box[0] && tool_box[0].length !== 0)}>
                  <Button color="success"
                          style={{height: "60px",
                            fontSize: "25px",
                            fontWeight: "bold",
                            width: "100%",
                            backgroundColor: "#3ea34c",
                            borderColor: "transparent"}}
                          onClick={activeTab === "cart" ? this.toggleCheckout.bind(this) : this.toggleReturn.bind(this)}>{activeTab === "cart" ? language["checkOut"] : language['return']}</Button>
                </Collapse>
              </Card>
            </Col>
            <Modal isOpen={checkout}>
              <ModalHeader style={{color: "#5ba918", fontSize: "50px"}}
                           className="d-flex justify-content-center">{checkConfirm ? language['processedCheckOut'] : language['confirmCheckOut']}</ModalHeader>
              {checkConfirm ?
                <ModalBody>
                  <CardText
                    style={{fontSize: "15px", color: "#005079"}}>{shop_user.name}, {language["successAdd"]}</CardText>
                  <CardText style={{color: "#005079"}}>{language['thankYou']}</CardText>

                </ModalBody> :
                <ModalBody>
                  <CardText style={{fontSize: "15px", color: "#005079"}}>
                    {language['confirmItems']} {shop_user.name}
                  </CardText>
                  <CardText style={{color: "#005079"}}>{language['thankYou']}</CardText>
                  <ListGroup>
                    {this.cart(shop_cart).map(x => {
                      return <ListGroupItem key={x.item[0].id}
                                            style={{paddingTop: "0px", paddingBottom: "0px", color: "#005079"}}>
                        <Row>
                          <Col xs="11">
                            <p style={{fontSize: "90%", margin: "4px"}}>{x.item[0].name}</p>
                          </Col>
                          <Col xs="1">
                            <p style={{fontSize: "90%", margin: "4px"}}>{x.count}</p>
                          </Col>
                        </Row>
                      </ListGroupItem>
                    })}
                  </ListGroup>
                </ModalBody>
              }
              {!checkConfirm && <CardFooter><Button color="danger"
                                                    onClick={this.toggleCheckout.bind(this)}> {language['cancel']} </Button><Button
                color="success" style={{float: "right"}}
                onClick={this.checkOut.bind(this)}> {language['confirm']} </Button></CardFooter>}
            </Modal>
            <Modal isOpen={returns}>
              <ModalHeader style={{color: "#5ba918", fontSize: "50px"}}
                           className="d-flex justify-content-center">{returnConfirm ? "Return Process" : "Confirm Return"}</ModalHeader>
              {returnConfirm ?
                <ModalBody>
                  <CardText style={{fontSize: "15px", color: "#005079"}}>{shop_user.name}, your return is being
                    processed please put the items back in their proper position.</CardText>
                  <CardText style={{color: "#005079"}}>Thank you!</CardText>
                </ModalBody> :
                <ModalBody>
                  <CardText style={{fontSize: "15px", color: "#005079"}}>
                    {shop_user.name}, please confirm these are the items you intend to return
                  </CardText>
                  <ListGroup>
                    {tool_box[0] && this.cart(tool_box[0].items.filter(x => item_ids.includes(x.id))).map(x => {
                      return <ListGroupItem key={x.item[0].id}
                                            style={{paddingTop: "0px", paddingBottom: "0px", color: "#005079"}}>
                        <Row>
                          <Col xs="11">
                            <p style={{fontSize: "90%", margin: "4px"}}>{x.item[0].material}</p>
                          </Col>
                          <Col xs="1">
                            <p style={{fontSize: "90%", margin: "4px"}}>{x.count}</p>
                          </Col>
                        </Row>
                      </ListGroupItem>
                    })}
                  </ListGroup>
                </ModalBody>
              }
              <CardFooter>{!returnConfirm &&
              <Button color="danger" onClick={this.toggleReturn.bind(this)}> Cancel </Button>} <Button color="success"
                                                                                                       style={{float: "right"}}
                                                                                                       onClick={returnConfirm ? this.toggleReturn.bind(this) : this.returnItems.bind(this)}> {returnConfirm ? "Complete" : "Confirm"} </Button></CardFooter>
            </Modal>
          </Row>
        </div>}
    </React.Fragment>;
  }
}

export default withRouter(connect(({shop_user, shop_materials, shop_cart, stock, timeoutTime, tool_box}) => {
  return {shop_user, shop_materials, shop_cart, stock, timeoutTime, tool_box}
})(Shop));
