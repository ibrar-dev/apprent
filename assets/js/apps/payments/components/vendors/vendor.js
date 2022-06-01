import React from "react";
import {connect} from "react-redux";
import {Input, Button, Label, Modal, ModalHeader, ModalBody, ModalFooter, Row, Col, Card} from "reactstrap";
import actions from "../../actions";
import icons from '../../../../components/flatIcons';

class Vendor extends React.Component {
    state = {
        ...this.props.vendor,
        edit: false,
        invalidAttributes: false,
        newCat: '',
        vendorModal: false,
        order: null
    };

    componentWillReceiveProps(props) {
        this.setState({...props.vendor});
    }

    change({target}) {
        this.setState({...this.state, [target.name]: target.value});
    }

    changeVendor(name){
        this.props.changeVendor(name)
    }

    render() {
        const {vendorCategories, properties} = this.props;
        const {name, email, address, phone, category_ids,property_ids,contact_name, edit, newCat} = this.state;
        const style = {
            border: '1px solid grey',
            borderRadius: '5px',
            maxHeight: '150px',
            overflowY: 'scroll'
        };

        return <tr onClick={this.changeVendor.bind(this, name)}>
            <td style = {{width:"350px"}}>
                <p className="m-0">
                    {name}
                </p>
            </td>
            <td>
                <ul className="list-unstyled">
                    <li>
                        <b>Email: </b>
                        {email}
                    </li>
                    <li>
                        <b>Address: </b>
                        {address}
                    </li>
                    <li>
                        <b>Phone: </b>
                        {phone}
                    </li>
                    <li>
                        <b>Contact Name: </b>
                        {contact_name || "N/A"}
                    </li>
                </ul>
            </td>
            <td style = {{width:"300px"}}>
                <Card style= {{ overflowY: "auto", paddingLeft: "0px", borderWidth: "0px" }}>
                    <ul className="list-unstyled">
                        {vendorCategories.map(p => (category_ids.includes(p.id)) && <li key={p.id}>
                            {p.name}
                        </li>)}
                    </ul>
                </Card>
            </td>
            <td style = {{width:"250px"}}>
                <Card style= {{maxHeight: "260px", overflowY: "auto", paddingLeft: edit ? "20px":"0px", borderWidth: edit ? "1px" : "0px" }}>
                    <ul className="list-unstyled" style= {{marginLeft: "0px"}}>
                        {properties.map(p => (property_ids.includes(p.id)) && <li key={p.id} >
                            {p.name}
                        </li>)}

                    </ul>
                </Card>
            </td>
        </tr>;

    }
}


export default connect(({vendorCategories, properties}) => {
    return {vendorCategories, properties}
})(Vendor)