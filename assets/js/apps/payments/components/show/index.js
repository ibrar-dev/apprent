import React, {useState, Component} from 'react';
import {Row, Col, Card, CardBody, CardHeader, Input} from 'reactstrap';
import {connect} from 'react-redux';
import {withRouter} from "react-router-dom";
import moment from 'moment';
import actions from "../../actions";
import {toCurr} from "../../../../utils";
import PdfExportButton from "../../../../utils/PdfExportButton";
import confirmation from "../../../../components/confirmationModal";

class ShowPayment extends Component {
  constructor(props) {
    super(props);
    const payment_id = window.location.pathname.match(/payments\/(\d+)/)[1];
    actions.fetchPaymentInfo(payment_id);
  }

  payment_type_of(payment) {
    if(payment.payment_type === "ba") {
      return "Bank Account";
    } else if (payment.payment_type === "cc") {
      return "Credit Card";
    } else if (payment.description === "Money Order") {
      return "Money Order";
    } else if (payment.description === "Check") {
      return "Check";
    } else {
      return "";
    }
  }

  clearError() {
    confirmation('Clear this error?').then(() => {
      actions.clearPostingError(this.props.payment.id)
    })
  }

  render() {
    const {payment} = this.props;

    let card;

    if(payment) {
      card = (
        <Card>
          <CardHeader>Payment #{payment.transaction_id}</CardHeader>
          <CardBody>
            <Row>
              <Col className="d-flex flex-column">
                <div className={`mt-1 ml-1 ${payment.tenant_id ? "" : "disabled-link"}`}>
                  Payer: <a
                    href={`/tenants/${payment.tenant_id}`}
                    target="_blank"
                  >
                    {payment.payer || payment.tenant_name || payment.payer_name}
                  </a>
                </div>
              </Col>
            </Row>
            <Row>
              <Col className="d-flex flex-column">
                <div className="labeled-box mt-4">
                  <Input value={payment.property_name || ''} disabled/>
                  <div className="labeled-box-label">Property</div>
                </div>
                <div className="labeled-box mt-3">
                  <Input value={payment.unit || ''} disabled/>
                  <div className="labeled-box-label">Unit</div>
                </div>
                <div className="labeled-box mt-3">
                  <Input value={toCurr(payment.amount)} disabled/>
                  <div className="labeled-box-label">Total</div>
                </div>
                <div className="labeled-box mt-3">
                  <Input value={this.payment_type_of(payment)} disabled/>
                  <div className="labeled-box-label">Payment Method</div>
                </div>
                {(payment.description === "Money Order" || payment.description === "Check") &&
                <div className="labeled-box mt-3">
                  <Input value={payment.transaction_id || ''} disabled/>
                  <div className="labeled-box-label">{payment.description} Number</div>
                </div>}
                <div className="labeled-box mt-3">
                  <Input value={payment.description} disabled/>
                  <div className="labeled-box-label">Description</div>
                </div>
                <div className="labeled-box mt-3">
                  <Input value={payment.source} disabled/>
                  <div className="labeled-box-label">Source</div>
                </div>
              </Col>
              <Col className="d-flex flex-column">
                <div className="labeled-box mt-4">
                  <Input value={moment(payment.inserted_at).format("MM/DD/YY hh:mm")} disabled/>
                  <div className="labeled-box-label">Date Received</div>
                </div>
                <div className="labeled-box mt-3">
                  <Input value={moment(payment.updated_at).format("MM/DD/YY hh:mm")} disabled/>
                  <div className="labeled-box-label">Date Updated</div>
                </div>
                <div className="labeled-box mt-3">
                  <Input value={moment(payment.post_month).format("MM/YY")} disabled/>
                  <div className="labeled-box-label">Post Month</div>
                </div>
                <div className="labeled-box mt-3">
                  <Input value={payment.payer_name} disabled/>
                  <div className="labeled-box-label">Payer Name</div>
                </div>
                {(payment.payment_type === "cc" || payment.payment_type === "ba") &&
                <div className="labeled-box mt-3">
                  <Input value={payment.last_4} disabled/>
                  <div className="labeled-box-label">Last 4</div>
                </div>}
              </Col>
            </Row>
            <Row>
              <Col className="d-flex flex-column">
                {payment?.response?.status && <div className="labeled-box mt-3 d-flex flex-column">
                  {Object.keys(payment.response).map((o, i) => {
                    return <Input key={i} value={`${o}: ${payment.response[o]}`} disabled/>
                  })}
                  <div className="labeled-box-label">Response</div>
                </div>}
                {payment.edits && payment.edits.length > 0 && <React.Fragment>
                  <hr/>
                  <span>Edits</span>
                  {payment.edits.map((e, i) => {
                    return <div key={i} className="labeled-box mt-2">
                      <Input value={moment(e["time"]).format("MM/DD/YY h:mm A")} disabled/>
                      {Object.keys(e).filter(o => o !== "time" && o !== "admin").map((o) => {
                        return <Input disabled value={`${o}: ${e[o]}`}/>
                      })}
                      <div className="labeled-box-label">{e["admin"]}</div>
                    </div>
                  })}
                </React.Fragment>}
              </Col>
              <Col>
                {payment.image &&
                <a download={`payment_${payment.transaction_id}`} target="_blank" href={payment.image}>
                  <img className="img-fluid" src={payment.image}/>
                </a>}
              </Col>
            </Row>
            <hr/>
            <Row>
              <Col>
                <div className="mt-1">Information Confirmed</div>
              </Col>
            </Row>
            { payment.payment_type == "cc" &&
              <>
                <Row className="mb-2">
                  <Col className="d-flex flex-column">
                    <div className="labeled-box mt-3">
                      <Input value={
                        payment.zip_code_confirmed_at ?
                          moment(payment.zip_code_confirmed_at).format('LLL')
                          : "Not Recorded"
                      } disabled/>
                      <div className="labeled-box-label">Payer Zip Code Confirmed (AVS)</div>
                    </div>
                  </Col>
                  <Col className="d-flex flex-column">
                    <div className="labeled-box mt-3">
                      <Input value={
                        payment.cvv_confirmed_at ?
                          moment(payment.cvv_confirmed_at).format('LLL')
                          : "Not Recorded"
                      } disabled/>
                      <div className="labeled-box-label">Payer CVV Confirmed</div>
                    </div>
                  </Col>
                </Row>
                <hr/>
              </>
            }
            <Row>
              <Col>
                <div className="mt-1">Payment Agreement</div>
              </Col>
            </Row>
            <Row className="mb-2">
              <Col className="d-flex flex-column">
                <div className="labeled-box mt-3">
                  <Input value={payment.payer_ip_address || "Not Recorded"} disabled/>
                  <div className="labeled-box-label">Payer IP Address</div>
                </div>
              </Col>
              <Col className="d-flex flex-column">
                <div className="labeled-box mt-3">
                  <Input value={
                    payment.agreement_accepted_at ? moment(payment.agreement_accepted_at).format('LLL') : "N/A"
                  } disabled/>
                  <div className="labeled-box-label">Agreement Signed At</div>
                </div>
              </Col>
            </Row>
            <hr/>
            <Row className="mt-2">
              <Col>
                <div dangerouslySetInnerHTML={{__html: payment.agreement_text}} />
              </Col>
            </Row>
            { payment.rent_application_terms_and_conditions && payment.rent_application_terms_and_conditions != "" &&
                <>
                  <hr/>
                  <Row>
                    <Col>
                      <div className="mt-1"><b>Rental Application Terms &amp; Conditions Agreement</b></div>
                    </Col>
                  </Row>
                  <Row className="my-2">
                    <Col>
                      <div dangerouslySetInnerHTML={{__html: payment.rent_application_terms_and_conditions}} />
                    </Col>
                  </Row>
                </>
            }
          </CardBody>
        </Card>
      )
    } else {
      card = <div>Loading</div>
    }

    let iconButton;

    if (payment) {
      iconButton = <PdfExportButton body={card} fileName={`payment-${payment.transaction_id}-export`} />
    } else {
      iconButton = null
    }

    return(
      <>
        <div className="mt-2 mb-3">
          {iconButton}
        </div>
        {payment.post_error && <div className="alert alert-danger">
          {payment.post_error}
          <div>
            <a onClick={this.clearError.bind(this)}>Clear Error</a>
          </div>
        </div>}
        {card}
      </>
    )
  }
}

export default withRouter(connect(({payment}) => {
  return {payment}
})(ShowPayment));
