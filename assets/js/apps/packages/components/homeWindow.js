import React from 'react';
import {connect} from "react-redux";
import moment from 'moment'
import {
  Container, Row, Col, Card, CardImg, CardText, CardBody,
  CardHeader, Input
} from 'reactstrap';
import Package from "./package";
import Pagination from '../../../components/pagination'
import Img from '../images/box.svg';
import PackagesImg from '../images/trolley.svg';
import ReturnPackage from '../images/shipping.svg';
import ToBeReturnPackage from '../images/returned.svg';
import PenPackage from '../images/storage.svg'
import HolPackage from '../images/warehouse.svg'

const dateReceivedSort = (o1, o2) => {
  const d1 = (new Date(o1.inserted_at)).getTime();
  const d2 = (new Date(o2.inserted_at)).getTime();
  return d1 - d2;
};

const dateDeliveredSort = (o1, o2) => {
  const d1 = o1.status == "Delivered" ? (new Date(o1.updated_at)).getTime() : 0;
  const d2 = o2.status == "Delivered" ? (new Date(o2.updated_at)).getTime() : 0;
  return d1 - d2;
};

const headers = [
  {label: 'Name', sort: 'name'},
  {label: 'Unit'},
  {label: 'Status', sort: 'status', min: true},
  {label: 'Carrier'},
  {label: 'Date Received', sort: dateReceivedSort},
  {label: 'Date Delivered', sort: dateDeliveredSort},
  {label: '', min: true}
];

const imgStyle = {
  width: "65px",
};

const cardStyle = {
  textAlign: 'center',
  cursor: 'pointer',
  width: "100%"
};

const cardStyleClicked = {
  textAlign: 'center',
  cursor: 'pointer',
  borderColor: "#465e77",
  width: "100%"
};

const cardHeaderStyle = {
  fontSize: "100%",
  fontWeight: "bold",
  color: "#506b83"
};

class HomeWindow extends React.Component {
    state = {filterVal: '', clicked:''};

    changeFilter(e){
        this.setState({...this.state, filterVal: e.target.value});
    }

    setFilter(e){
        this.setState({...this.state, clicked: e});
    }

    _filters() {
        const {filterVal} = this.state;
        return <Input value={filterVal} onChange={this.changeFilter.bind(this)}/>
    }

    filtered() {
        const {filterVal} = this.state;
        const {packages} = this.props;
        const regex = new RegExp(filterVal, 'i');
        const regex2 = new RegExp(this.state.clicked, 'i')
        return packages.filter(p => {
            return (p.name.match(regex) || p.unit.match(regex) || p.property.match(regex) || p.carrier.match(regex)) && (p.status.match(regex2)) ;
        });
    }

    render(){
        const {packages} = this.props;
        const {clicked} = this.state;
        const packagesInLastWeek = packages.filter(x => moment(x.inserted_at) >= moment().subtract(7, 'days')).length;
        return <Container>
            <Row className="d-flex justify-content-end"><h6 className="text-muted" style = {{float: "right", paddingTop: "16px", marginRight:"20px", marginBottom:"30px"}}> {moment().format('MMMM Do YYYY')}, {packagesInLastWeek} packages in 7 days</h6></Row>
            <Row>
                <Col>
                    <Card style={clicked == '' ? cardStyleClicked : cardStyle } onClick={this.setFilter.bind(this, '' )}>
                        <CardHeader style={cardHeaderStyle}>Total Packages</CardHeader>
                        <CardBody>
                            <CardImg top style = {imgStyle} src={PackagesImg} alt="Card image cap" />
                        <CardText style={{fontSize: "25px", color: "#808080"}}> {packages.length} </CardText>
                        </CardBody>
                    </Card>
                </Col>
                <Col>
                    <Card style={clicked == 'pending' ? cardStyleClicked : cardStyle } onClick={this.setFilter.bind(this, 'pending' )}>
                        <CardHeader style={cardHeaderStyle}>Pending</CardHeader>
                        <CardBody>
                            <CardImg top style = {imgStyle} src={PenPackage} alt="Card image cap" />
                            <CardText style={{fontSize: "25px", color: "#808080"}}> {packages.filter(x => x.status.toLowerCase() == "pending").length}</CardText>
                        </CardBody>
                    </Card>
                </Col>
                <Col>
                    <Card style={clicked == 'hold' ? cardStyleClicked : cardStyle } onClick={this.setFilter.bind(this, 'hold')}>
                        <CardHeader style={cardHeaderStyle}>Hold</CardHeader>
                        <CardBody>
                            <CardImg top style = {imgStyle} src={HolPackage} alt="Card image cap" />
                            <CardText style={{fontSize: "25px", color: "#808080"}}> {packages.filter(x => x.status.toLowerCase() == "hold").length}</CardText>
                        </CardBody>
                    </Card>
                </Col>
                <Col>
                    <Card style={clicked == 'delivered' ? cardStyleClicked : cardStyle } onClick={this.setFilter.bind(this, 'delivered')}>
                        <CardHeader style={cardHeaderStyle}>Delivered</CardHeader>
                        <CardBody>
                            <CardImg top style = {imgStyle} src={Img} alt="Card image cap" />
                            <CardText style={{fontSize: "25px", color: "#808080"}}> {packages.filter(x => x.status.toLowerCase() == "delivered").length}</CardText>
                        </CardBody>
                    </Card>
                </Col>
                <Col>
                    <Card style={clicked == 'undeliverable' ? cardStyleClicked : cardStyle } onClick={this.setFilter.bind(this, 'undeliverable')}>
                        <CardHeader style={cardHeaderStyle}>Undeliverable</CardHeader>
                        <CardBody>
                            <CardImg top style = {imgStyle} src={ToBeReturnPackage} alt="Card image cap" />
                            <CardText style={{fontSize: "25px", color: "#808080"}}> {packages.filter(x => x.status.toLowerCase() == "undeliverable").length} </CardText>
                        </CardBody>
                    </Card>
                </Col>
            <Col>
                <Card style={clicked == 'returned' ? cardStyleClicked : cardStyle } onClick={this.setFilter.bind(this, 'returned')}>
                    <CardHeader style={cardHeaderStyle}>Returned</CardHeader>
                    <CardBody>
                        <CardImg top style = {imgStyle} src={ReturnPackage} alt="Card image cap" />
                    <CardText style={{fontSize: "25px", color: "#808080"}}> {packages.filter(x => x.status.toLowerCase() == "returned").length} </CardText>
                    </CardBody>
                </Card>
            </Col>
            </Row>
            <Pagination
                title="Packages"
                collection={this.filtered()}
                headers={headers}
                component={Package}
                filters={this._filters()}
                field="pack"
                hover={true}
            />

        </Container>

    }
}

export default connect(packages => {
  return packages
})(HomeWindow)