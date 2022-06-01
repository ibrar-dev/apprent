import React, {} from "react";
import {Spin} from "antd";
import CurrentlyOpen from "./CurrentlyOpen";
import ReviewedPercentage from "./ReviewedPercentage";
import AvgRating from "./AvgRating";
import AvgCallback from "./AvgCallbacks";
import AvgCompletionTime from "./AvgCompletionTime";
import CompletionPercent from "./CompletionPercent";
import TotalCompleted from "./TotalCompleted";
import PerformanceScore from "./PerformanceScore";

function InfoBox({
  caret, value, title, fetching, subtitle="From 30 days prior"
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
            {subtitle}
          </small>
        </span>
      </div>
    </Spin>
  );
}

function calculatePercentageChange(current, old) {
  return Math.abs(Math.round(((current - old) / old) * 100));
}

function calculateDifference(current, old) {
  const num = Math.abs((current - old));
  if (Number.isInteger(num)) return num;
  return num.toFixed(1);
}

function InfoBoxes({properties}) {
  const childProps = {
    InfoBox, calculatePercentageChange, properties, calculateDifference,
  };

  let performanceScore

  if (window.roles.includes("Super Admin")) {
    performanceScore = <div className="d-flex flex-row justify-content-center mx-2 my-2">
      <PerformanceScore {...childProps} />
    </div>
  }

  return (
    <div className="d-flex flex-wrap justify-content-between">
      <div className="d-flex flex-row justify-content-center mx-2 my-2">
        <CurrentlyOpen {...childProps} />
      </div>
      <div className="d-flex flex-row justify-content-center mx-2 my-2">
        <CompletionPercent {...childProps} />
      </div>
      <div className="d-flex flex-row justify-content-center mx-2 my-2">
        <TotalCompleted {...childProps} />
      </div>
      <div className="d-flex flex-row justify-content-center mx-2 my-2">
        <ReviewedPercentage {...childProps} />
      </div>
      <div className="d-flex flex-row justify-content-center mx-2 my-2">
        <AvgRating {...childProps} />
      </div>
      <div className="d-flex flex-row justify-content-center mx-2 my-2">
        <AvgCallback {...childProps} />
      </div>
      <div className="d-flex flex-row justify-content-center mx-2 my-2">
        <AvgCompletionTime {...childProps} />
      </div>
      {performanceScore}
    </div>
  );
}

export default InfoBoxes;
