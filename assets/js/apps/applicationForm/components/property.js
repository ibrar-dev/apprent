import React from 'react';
import {connect} from 'react-redux';
import LoadForm from "./loadForm";
import {Card} from "reactstrap";
import {toCurr} from "../../../utils";

class Property extends React.Component {
  _propertyDisplay() {
    const {property} = this.props;
    if (!property) return null;
    if (property.logo) return <div className="property-logo">
      <img src={property && property.logo}/>
    </div>;
    return <h5 className="d-flex justify-content-center">
      {property && property.name}
    </h5>;
  }

  render() {
    const {property} = this.props;
    return <div>
      <Card className="border-0 px-3 property-info mb-3">
        <div style={{color: "#48a554"}} className="align-items-center">
          {this._propertyDisplay()}
        </div>
        <a className="btn btn-success btn-block mb-3 btn-rounded" href={`/showings/${property && property.code}`}>
          Schedule a Tour
        </a>
        {!window.APPLICATION_JSON && <LoadForm />}
        <div className="btn btn-outline-primary btn-block disabled mt-2 btn-rounded">Application Fee: {toCurr(property.application_fee)} Per Lease Holder</div>
        <div className="btn btn-outline-primary btn-block disabled mt-2 btn-rounded">Admin Fee: {toCurr(property.admin_fee)} Per Application</div>
      </Card>
    </div>
  }
}

export default connect(({stage, application, language, property}) => {
  return {stage, application, language, property};
})(Property);