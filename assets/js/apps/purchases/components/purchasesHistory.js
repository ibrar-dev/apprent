import React, { useState } from "react";
import moment from "moment";
import { Button, Input, ButtonGroup } from "reactstrap";
import { connect } from "react-redux";
import actions from "../actions";
import confirmation from "../../../components/confirmationModal";
import MultiPropertySelect from "../../../components/multiPropertySelect";
import InfoBoxes from "./infoBoxes/index";

const divStyle = {
  fontWeight: 'bold',
  fontSize: 'large',
  padding: '10px',
  textAlign: 'center'
}

const PurchasesHistory = ({ purchases }) => {
  const [selectedProperties, setSelectedProperties] = useState([])

  const updateStatus = (p, status) => {
    actions.updatePurchase({ ...p, status })
  }

  const deletePurchase = (purchase) => {
    confirmation('Really cancel this purchase?').then(() => {
      actions.deletePurchase(purchase);
    });
  }

  const purchaseLengthMessage = (filteredPurchases) => {
    if (selectedProperties.length === 0) return "Please select a property"
    if (selectedProperties.length === 1 && filteredPurchases.length === 0) return "This property has no purchases"
    if (selectedProperties.length > 0 && filteredPurchases.length === 0) return "These properties have no purchases"
  }

  const filteredPurchases = purchases.filter((purchase) => (
    selectedProperties.includes(purchase.property_id)
  )
  )
  return (
    <div>
      <div>
        <MultiPropertySelect
          className={"flex-fill w-100"}
          onChange={(ids) => setSelectedProperties(ids)}
        />
      </div>
      <div>
        <InfoBoxes properties={selectedProperties} />
      </div>
      <div style={divStyle}>
        {purchaseLengthMessage(filteredPurchases)}
      </div>
      <div>
        <ul className="list-group mt-3">
          {filteredPurchases.map((p) => (
            <li key={p.id} className="list-group-item d-flex justify-content-between align-items-center">
              <div className="d-flex justify-content-center align-items-center position-relative overflow-hidden">
                <div
                  className="d-flex align-items-center justify-content-center rounded-circle bg-white mr-2"
                  style={{ width: 40, height: 40, border: "1px solid rgba(0, 0, 0, 0.2)" }}
                >
                  {p.reward.icon ? <img src={p.reward.icon} className="w-100" /> : <i className="fas fa-question" />}
                </div>
                <div>
                  <h3 className="m-0">{p.reward.name}</h3>
                  <div>
                    <a href={`/tenants/${p.tenant.id}`}>
                      {p.tenant.first_name}
                      {" "}
                      {p.tenant.last_name}
                      {" "}
                    --
                  {" "}
                      {p.property}
                    </a>
                  </div>
                </div>
              </div>
              <div>
                {moment(p.inserted_at).format("MMMM DD, YYYY")}
              </div>
              <ButtonGroup>
                <Button
                  color="info"
                  outline={p.status !== "pending"}
                  onClick={() => updateStatus(p, "pending")}
                >
                  Pending
              </Button>
                <Button
                  color="info"
                  outline={p.status !== "ordered"}
                  onClick={() => updateStatus(p, "ordered")}
                >
                  Ordered
              </Button>
                <Button
                  color="info"
                  outline={p.status !== "delivered"}
                  onClick={() => updateStatus(p, "delivered")}
                >
                  Delivered
              </Button>
              </ButtonGroup>
              <ButtonGroup>
                {p.reward.url && (
                  <a className="btn btn-outline-info" href={p.reward.url} target="_blank">
                    <i className="fas fa-shopping-cart" />
                  </a>
                )}
                {!p.reward.url && (
                  <Button outline color="info" disabled>
                    <i className="fas fa-shopping-cart" />
                  </Button>
                )}
                <Button color="danger" outline onClick={() => deletePurchase(p)} disabled={p.status !== "pending"}>
                  <i className="fas fa-times" />
                </Button>
              </ButtonGroup>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}

export default connect(({ purchases }) => ({ purchases }))(PurchasesHistory);
