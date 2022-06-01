import React, {useEffect, useState} from "react";
import axios from "axios"

function PerformanceScore({properties, InfoBox}) {
  const [score, setScore] = useState("N/A")
  const [fetching, setFetching] = useState(false)

  // Properties will be in one of the following formats, annoyingly:
  // "123,456"
  // ""
  // [123, 345]
  // []
  //
  // I'm not sure why it's coming in those different ways. Nevertheless, we must
  // handle it appropriately.
  useEffect(() => {
    let propertyIds

    // Handle "123,345" and [123, 345] with equal grace
    if (typeof(properties) === "string") {
      propertyIds = properties.split(",")
    } else {
      propertyIds = properties || []
    }

    // If no properties are selected and we have a string, we get [""], which we
    // don't want. We filter that as well as any other non-numerics out.
    propertyIds = propertyIds.filter((element) => String(element).match(/\d+/))

    // If we have one and only one property, fetch data. Otherwise, show "N/A"
    if(propertyIds.length == 1) {
      const propertyId = propertyIds[0]

      const fetchData = async () => {
        setFetching(true);
        const result = await axios(`/api/maintenance_reports?property=${propertyId}&type=performance_score`);
        setScore(result.data?.current || "N/A")
        setFetching(false);
      }
      fetchData();
    } else {
      setScore("N/A")
    }
  }, [properties])

  const value = <h1>{score}</h1>

  return(
    <InfoBox
      value={value}
      title="Performance Score"
      fetching={fetching}
      subtitle="Last 24 Hours"
    />
  )
}

export default PerformanceScore;
