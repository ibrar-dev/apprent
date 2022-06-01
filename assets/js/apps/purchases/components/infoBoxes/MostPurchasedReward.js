import React, {useEffect, useState} from 'react';
import axios from 'axios';
import { Button, ButtonGroup } from "reactstrap";

const MostPurchasedReward = ({properties, InfoBox}) => {
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

  const value = data?.most_purchased_reward_names ? 
    data?.most_purchased_reward_names[range].slice(0,3).map(rewards => <div key ={rewards} style = {divStyle}>{rewards}</div>) : 
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
        title="Most Purchased Reward"
        fetching={fetching}
      />
    </div>
  )
}

export default MostPurchasedReward;