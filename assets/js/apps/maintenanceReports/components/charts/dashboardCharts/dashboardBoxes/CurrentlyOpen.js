import React, {useEffect, useState} from 'react';
import axios from 'axios';

function CurrentlyOpen({properties, calculateDifference, InfoBox}) {
  const [data, setData] = useState({});
  const [fetching, setFetching] = useState(false);

  useEffect(() => {
    if (properties && properties.length) {
      const fetchData = async () => {
        setFetching(true);
        const result = await axios(`/api/maintenance_reports?dates&properties=${properties}&type=info_box_open`);
        setData(result.data);
        setFetching(false);
      }
      fetchData();
    }
  }, [properties])

  const caret = () => (
    <span>
      <i className={`text-${data.indicator ? 'success' : 'danger'} fas fa-caret-${data.indicator ? 'down' : 'up'}`} />
      {" "}{calculateDifference(data.current, data.comparison)}
    </span>
  )

  const value = () => (<h1>{data.current ? data.current : '0'}</h1>)

  return (
    <InfoBox
      caret={caret()}
      value={value()}
      title="Open Work Orders"
      fetching={fetching}
    />
  )
}

export default CurrentlyOpen;
