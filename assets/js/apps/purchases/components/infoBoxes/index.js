import React, {} from "react";
import {Button, Spin} from "antd";
import MostPurchasedReward from "./MostPurchasedReward";
import HighestScoringTenant from "./HighestScoringTenant";
import MostFrequentAccomplishmentType from "./MostFrequentAccomplishmentType"

function InfoBox({
  caret,
  value,
  title,
  fetching,
}) {
  return (
    <Spin spinning={fetching}>
      <div className="d-flex flex-column">
        <p className="text-muted">{title}</p>
        <div>{value}</div>
        <span>
          {caret}
          <small>
            {" "}
          </small>
        </span>
      </div>
    </Spin>
  );
}

function InfoBoxes({properties}) {
  return (
    <div className="d-flex flex-wrap justify-content-between">
        <div className="d-flex flex-row justify-content-center mx-2 my-2">
          <MostPurchasedReward InfoBox={InfoBox} properties={properties} />
        </div>
      <div className="d-flex flex-row justify-content-center mx-2 my-2">
        <HighestScoringTenant InfoBox={InfoBox} properties={properties} />
      </div>
      <div className="d-flex flex-row justify-content-center mx-2 my-2">
        <MostFrequentAccomplishmentType InfoBox={InfoBox} properties={properties} />
      </div>
    </div>
  );
}

export default InfoBoxes;
 