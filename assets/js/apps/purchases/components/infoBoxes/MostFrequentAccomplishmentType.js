import React, {useEffect, useState} from 'react';
import axios from 'axios';
import { Button, ButtonGroup } from "reactstrap";


const MostFrequentAccomplishmentType = ({properties, InfoBox}) => {
  const [range, setRange] = useState("mtd")
  const [data, setData] = useState({});
  const [fetching, setFetching] = useState(false);

  useEffect(() => {
    if (properties && properties.length) {
      const fetchData = async () => {
        setFetching(true);
        const result = await axios(`/api/rewards_analytics?infoBox&properties=${properties}`);
        setData(result.data);
        setFetching(false);
      }
      fetchData();
    }
  }, [properties, range])

  const divStyle = {
    fontWeight: "bold",
    fontSize: "12pt",
  }

  const value = data?.most_frequent_accomplishment_type ? 
    data?.most_frequent_accomplishment_type[range].slice(0,3).map(accomplishment => <div key ={accomplishment} style = {divStyle}>{accomplishment}</div>) : 
    <div>"No Data"</div>;

  return (
    <div>
      <ButtonGroup>
        <Button
          style={{ marginTop: "10px" }}
          outline
          disabled={fetching}
          active={range === 'mtd'}
          onClick={() => setRange('mtd')}
          color="info">
          MTD
        </Button>
        <Button
          style={{ marginTop: "10px" }}
          outline
          disabled={fetching}

          active={range === 'ytd'}
          onClick={() => setRange('ytd')}
          color="info">
          YTD
        </Button>
      </ButtonGroup>
      <InfoBox
        value={value}
        title="Most Frequent Accomplishment"
        fetching={fetching}
      />
    </div>
  )
}

export default MostFrequentAccomplishmentType;