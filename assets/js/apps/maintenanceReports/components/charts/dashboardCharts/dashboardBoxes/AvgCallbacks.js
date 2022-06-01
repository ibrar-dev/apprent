import React, {useEffect, useState} from "react";
import axios from "axios";

function AvgCallback({properties, calculatePercentageChange, InfoBox}) {
  const [data, setData] = useState({});
  const [fetching, setFetching] = useState(false);

  useEffect(() => {
    if (properties && properties.length) {
      const fetchData = async () => {
        setFetching(true);
        const result = await axios(`/api/maintenance_reports?dates&properties=${properties}&type=info_box_callback`);
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
      {calculatePercentageChange(data.current, data.comparison)}
      %
    </span>
  );

  const value = () => (
    <h1>
      {data.current ? Number(data.current).toFixed(1) : "0"}
      <small>%</small>
    </h1>
  );
  return (
    <InfoBox
      caret={caret()}
      value={value()}
      title="30 Day Average Callbacks"
      fetching={fetching}
    />
  );
}

export default AvgCallback;
