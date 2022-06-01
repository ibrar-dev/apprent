import React, {useEffect, useState} from 'react';
import axios from 'axios';

function AvgRating({properties, InfoBox, calculateDifference}) {
  const [data, setData] = useState({});
  const [fetching, setFetching] = useState(false);

  useEffect(() => {
    if (properties && properties.length) {
      const fetchData = async () => {
        setFetching(true);
        const result = await axios(`/api/maintenance_reports?dates&properties=${properties}&type=info_box_rating`);
        setData(result.data);
        setFetching(false);
      }
      fetchData();
    }
  }, [properties])

  const caret = () => (
    <span>
      <i className={`text-${data.indicator ? 'success' : 'danger'} fas fa-caret-${data.indicator ? 'up' : 'down'}`} />
      {" "}{calculateDifference(data.current, data.comparison)}
    </span>
  )

  const value = () => (<h1>{data.current ? Number(data.current).toFixed(1) : 'N/A'}</h1>)

  return (
    <InfoBox
      caret={caret()}
      value={value()}
      title="30 Day Average Rating"
      fetching={fetching}
    />
  )
}

export default AvgRating;
