import React from 'react';
import {Card, CardBody, CardTitle, Button} from 'reactstrap';

class editLease extends React.Component {


    render() {
        return (
            <div  style={{}}>
                {this.props.children}
                <Button outline onClick={this.props.save}>
                    <i className="fas fa-check"></i> Save
                </Button>
            </div>
        )
    };

}


export default editLease;