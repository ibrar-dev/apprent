import React, {useEffect, useState} from "react";
import axios from "axios";
import moment from "moment";

function AvgCompletionTime({properties, InfoBox}) {
  const [data, setData] = useState({});
  const [fetching, setFetching] = useState(false);

  useEffect(() => {
    if (properties && properties.length) {
      const fetchData = async () => {
        setFetching(true);
        const result = await axios(`/api/maintenance_reports?dates&properties=${properties}&type=info_box_completion_time`);
        setData(result.data);
        setFetching(false);
      };
      fetchData();
    }
  }, [properties]);

  const caret = () => (
    <span>
      <i className={`text-${data.indicator ? "success" : "danger"} fas fa-caret-${data.indicator ? "down" : "up"}`} />
      {" "}
      {moment.duration(data.current - data.comparison, "seconds").asDays().toFixed(1)}
    </span>
  );

  const value = () => (
    <h1>
      {data.current ? moment.duration(data.current, "seconds").asDays().toFixed(1) : "N/A"}
      {" "}
      <small>Days</small>
    </h1>
  );
  return (
    <InfoBox
      caret={caret()}
      value={value()}
      title="30 Day Completion Time"
      fetching={fetching}
    />
  );
}

export default AvgCompletionTime;
