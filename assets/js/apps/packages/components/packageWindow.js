import React from "react";
import {connect} from "react-redux";
import {Input, Card, CardBody, Row, Col, CardHeader, Container} from "reactstrap";



class PackageWindow extends React.Component {
    state = {filterVal: ''};

    changeFilter(e){
        this.setState({...this.state, filterVal: e.target.value});
    }

    _filters() {
        const {filterVal} = this.state;
        return <Input value={filterVal} onChange={this.changeFilter.bind(this)}/>
    }

    filtered() {
        const {filterVal} = this.state;
        const {packages} = this.props;
        const regex = new RegExp(filterVal, 'i');
        return packages.filter(p => {
            return p.name.match(regex) || p.unit.match(regex) || p.status.match(regex) || p.carrier.match(regex) ;
        });
    }

    render() {
        const {packages} = this.props;
        const reducedPackages = {};
        return <Container>
            <Card  size='lg'>
            <CardHeader>
                Lobby Display
            </CardHeader>
            <CardBody >
                <Row style = {{}} className="text-center">
                    {packages.map(p => {

                        (p.status == "Pending") && (reducedPackages[p.unit] == null ? reducedPackages[p.unit] = 1  : reducedPackages[p.unit]++)

                    })}
                    {Object.keys(reducedPackages).map(k => {
                        const style = { width : "150px", display : "inline-block", margin : "5px"}
                        return <Col key={k}>
                            <Card key={k} style = {style}>
                                <CardHeader >
                                    {k}
                                </CardHeader>
                                <CardBody className="text-center" >
                                    {reducedPackages[k]}
                                </CardBody>
                            </Card>
                        </Col>
                    })
                    }
                </Row>
            </CardBody>
        </Card>
        </Container>
    }
}

export default connect(packages => {
    return (packages);
})(PackageWindow)