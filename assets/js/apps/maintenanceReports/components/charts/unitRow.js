import React from "react";
import {connect} from "react-redux";
import {Card, Col, CardBody, CardText, Row, ListGroup, ListGroupItem, Collapse} from "reactstrap";
import actions from "../../actions";


class UnitRow extends React.Component {
  state = {};
  constructor(props) {
    super(props);
    this.imgRef = React.createRef();
  }

  setAdmin(admin){
    actions.setAdmin(admin);
  }

  collapseToggle(){
    this.setState({...this.state, collapse: !this.state.collapse})
  }

  render() {
    const {unit} = this.props;
    const {collapse} = this.state;
    return <Col md={3}>
      <Card style={{}} onClick={this.collapseToggle.bind(this)}>
        <CardBody>
          <div className="d-flex flex-row justify-content-between">
          <div style={{fontSize:15, fontWeight:"bold", margin:0}}><i style={{color:"#5dbd77"}} className="fas fa-home"></i>  {unit.details && unit.details.number}</div>
            <div style={{fontSize:15, fontWeight:"bold", margin:0}}><h6 className="d-flex" style={{color:'#898a96'}}>Open Orders: {unit.orders && unit.orders.length}</h6></div>
          </div>
          <Collapse isOpen={collapse}>
          <ListGroup style={{marginTop:5}}>
            {unit.orders && unit.orders.length > 0 && unit.orders.map(x => {
              return <ListGroupItem><h6>{x.category}</h6></ListGroupItem>
            })}
          </ListGroup>
          </Collapse>
        </CardBody>
      </Card>
    </Col>
  }
}

export default connect(({}) => {
  return {};
})(UnitRow)
