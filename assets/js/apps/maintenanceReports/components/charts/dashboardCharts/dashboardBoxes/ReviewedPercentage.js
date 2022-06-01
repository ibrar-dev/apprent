import React, {useEffect, useState} from 'react';
import axios from 'axios';

function CompletionPercent({properties, InfoBox, calculatePercentageChange}) {
  const [data, setData] = useState({});
  const [fetching, setFetching] = useState(false);

  useEffect(() => {
    if (properties && properties.length) {
      const fetchData = async () => {
        setFetching(true);
        const result = await axios(`/api/maintenance_reports?dates&properties=${properties}&type=info_box_reviewed_percent`);
        setData(result.data);
        setFetching(false);
      }
      fetchData();
    }
  }, [properties])

  const caret = () => (
    <span><i className={`text-${data.indicator ? 'success' : 'danger'} fas fa-caret-${data.indicator ? 'up' : 'down'}`} />
      {" "}{calculatePercentageChange(data.current, data.comparison)}%
    </span>
  )

  const value = () => (<h1>{data.current ? Number(data.current).toFixed(1) : '0'}<small>%</small></h1>)

  return (
    <InfoBox
      caret={caret()}
      value={value()}
      title="Reviewed Percentage"
      fetching={fetching}
    />
  )
}

export default CompletionPercent;
