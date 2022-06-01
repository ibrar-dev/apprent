import React from "react";
import {connect} from "react-redux";
import {Input, Button, Label, Modal, ModalHeader, ModalBody, ModalFooter, Row, Col, Card} from "reactstrap";
import actions from "../actions";
import HVAC from '../media/air-conditioner.svg';
import Paint from '../media/paint-brush.svg';
import Electric from '../media/flash.svg';
import Safety from '../media/fire-extinguisher.svg';
import Grass from '../media/grass.svg';
import Pool from '../media/swimming-pool.svg';
import Light from '../media/lightbulb.svg';
import Clean from '../media/spray.svg';
import Plumbing from '../media/toilet.svg';
import Tools from '../media/settings.svg';
import Appliances from '../media/washing-machine.svg';
import Door from '../media/handle.svg';
import Gears from '../media/gears.svg';


const types = {"HVAC PARTS": HVAC, "PAINT & SUNDRIES": Paint, "ELECTRICAL": Electric, "SAFETY & SIGNAGE": Safety,
    "GROUNDS & IRRIGATION": Grass, "POOL SUPPLIES": Pool, "LIGHTING": Light, "JANITORIAL & CLEANING": Clean,
    "PLUMBING": Plumbing, "TOOLS": Tools, "APPLIANCES": Appliances, "WINDOWS, DOORS & FLOORS": Door, "HARDWARE": Gears};

class Item extends React.Component {
  state = {
    ...this.props.item,
    item_ids:[]
  };

  addToCart(){
      const stock_id = window.location.pathname.match(/materials\/(\d+)/)[1];
      if(!this.cart(this.props.shop_cart).filter(x => x.material_id === this.props.item.id)[0] ||
          !(this.cart(this.props.shop_cart).filter(x => x.material_id === this.props.item.id)[0].count === this.props.item.inventory)) {
          actions.addItemToCart(this.state, stock_id, this.props.shop_user.id);
      }
      actions.resetTime();
  }

    cart(cart){
        let newCart = [];
        let found = false;
        cart.map(x => {
            newCart.find((y,i) => {
                if(y.item[0].material_id === x.material_id){
                    newCart[i].count++;
                    newCart[i].item.push(x);
                    found = true;
                }
            });
            if (!found || !newCart[0]) newCart.push({item:[x], count: 1});
            found = false;
        });
        return newCart;
    }

  render() {
    const {name, id, type} = this.state;
    const {shop_cart} = this.props;
    return <tr key={id} style={this.props.index % 2 === 0 ? {color:"#565656",fontSize:"14px"} : {color:"#565656",fontSize:"14px", backgroundColor:"#fbfbfb"}}>
        <td  style={{verticalAlign:"middle", paddingTop:"5px", paddingBottom:"5px", maxWidth:"50px", padding:"12px", border:"solid 1px #e4e6eb", borderTopLeftRadius:"25px", borderBottomLeftRadius:"10px", borderRight:"none",borderTop:"none"}}>
            { types[type] ? <img src={types[type]} alt="Smiley face" height="30" width="30" /> :
                <p style={{marginBottom:"0px"}}>
                    {type}
                </p>
            }
        </td>
          <td  style={{verticalAlign:"middle", padding:"12px", border:"solid 1px #e4e6eb", borderLeft:"none", borderRight:"none",borderTop:"none"}}>
              <p style={{marginBottom:"0px"}}>
                  {name}
              </p>
          </td>
          <td style={{fontSize:"18px",verticalAlign:"middle", padding:"12px",border:"solid 1px #e4e6eb", borderLeft:"none", borderRight:"none", borderTop:"none"}}>
              <p  style={{marginBottom:"0px"}}>
                  {this.props.item.inventory}
              </p>
          </td>

        <td style = {{width:"50px", padding:"12px", border:"solid 1px #e4e6eb", borderLeft:"none", borderRight:"none", borderTop:"none"}}>
            <Button onClick={this.addToCart.bind(this)} className="btn btn-outline"
                    style={shop_cart.some(x => x.material_id === id) ? {color:"#4fa4ff", backgroundColor:"transparent", borderColor:"#4fa4ff"} :
                        {color:"#475f78", backgroundColor:"transparent", borderColor:"#475f78"}}
                    to="/materials/shop" >
                <i className="fas fa-cart-plus" />
            </Button>
        </td>
      </tr>;

  }
}


export default connect(item => {
  return item;
})(Item);