import React, {Component, Fragment} from "react";
import {connect} from "react-redux";
import {HorizontalBar} from "react-chartjs-2";
import {Row, Col, Card, CardBody, Table, CardTitle} from "reactstrap";
import moment from "moment";
import ChartDataLabels from "chartjs-plugin-datalabels";
import {Chart} from "react-chartjs-2";
import actions from "../../actions";
import PropertySelect from "../../../../components/propertySelect";

Chart.plugins.unregister(ChartDataLabels);

const barChartData1 = (stats) => {
  const labels = [];
  const average_completion_time = [];
  const total_completed = [];
  stats.forEach(m => {
    total_completed.push(m.total_completed || 0);
    average_completion_time.push(moment.duration(m.average_completion_time, "seconds").asHours().toFixed(2) || "");
    labels.push(moment(m.month).format("MMMM"))
  })
  return {
    datasets: [
      {data: total_completed, label: "Total Completed"},
      {data: average_completion_time, label: "Average Completion Time (hours)", backgroundColor: "#fc8f7e"}

    ],
    labels: labels
  }
}

const barChartData2 = (stats) => {
  const labels = [];
  const total_vacants = [];
  const make_readies = [];
  stats.forEach(m => {
    total_vacants.push(m.vacants || 0);
    make_readies.push(m.make_readies || 0);
    labels.push(moment(m.month).format("MMMM"))
  })
  return {
    datasets: [
      {data: total_vacants, label: "Total Vacant", backgroundColor: "#b3e7ff"},
      {data: make_readies, label: "Made Ready", backgroundColor: "#f2c1f7"}

    ],
    labels: labels
  }
}

const tableData = (stats) => {
  const tableHeaders = [];
  const total_vacants = [];
  const make_readies = [];
  const average_completion_time = [];
  const total_completed = [];
  const avg_rating = [];
  const total_rated = [];
  const total_submitted = [];
  const lineItems = [
    "Submitted Work Orders",
    "Completed Work Orders",
    "Average Completion Time",
    "Month End Vacancy",
    "Made Ready",
    "⭐ Avg. Rating",
    "Rated Work Orders"
  ];

  stats.forEach(m => {
    total_submitted.push(m.total_submitted || 0);
    total_completed.push(m.total_completed || 0);
    average_completion_time.push(moment.duration(m.average_completion_time, "seconds").asHours().toFixed(2) || 0);
    tableHeaders.push(moment(m.month).format("MMMM"))
    total_vacants.push(m.vacants || 0);
    make_readies.push(m.make_readies || 0);
    avg_rating.push(m.avg_rating > 0 ? parseFloat(m.avg_rating).toFixed(1) : "- -");
    total_rated.push(m.total_rating || 0)
  });

  let rows = [total_submitted, total_completed, average_completion_time, total_vacants, make_readies, avg_rating, total_rated];

  let rowData = rows.map((i, index) => {
    return (
      <tr key={index}>
        <th scope="row" key={index}>{lineItems[index]}</th>
        {i.map((stat, i) => <td key={i}>{stat}</td>)}
      </tr>
    )
  })

  return (
    <div style={{margin: "100px"}}>
      <div className="text-center">
        <h5>Table View</h5>
      </div>
      <Row>
        <Table bordered size="sm">
          <thead>
          <tr>
            <th></th>
            {tableHeaders.map((h, i) => <th key={i}>{h}</th>)}
          </tr>
          </thead>
          <tbody>
          {rowData}
          </tbody>
        </Table>
      </Row>
    </div>
  )
}

class Synopsis extends Component {
  state = {}

  constructor(props) {
    super(props);
  }

  rating() {
    const {selectedProperty} = this.state;
    const {reports} = this.props;
    const property = reports.find(property => property.name === selectedProperty.name);
    if (!property) return;

    function stars() {
      const stars = [];

      function width(number) {
        if (!number) {
          return "0%"
        }
        let fill = number < 0 ? 0 : (number > 1 ? "100%" : `${number * 100}%`);
        return fill;
      }

      for (let i = 0; i < 5; i++) {
        stars.push(<div key={i} className="position-relative d-inline mr-1 text-left">
          <i className="far fa-star text-warning"/>
          <i style={{width: width(rating - i), top: "2px", left: 0, overflow: "hidden"}}
             className="fas fa-star position-absolute text-warning"/>
        </div>)
      }
      return stars;
    }

    const rating = property.rating ? Number.parseFloat(property.rating).toFixed(1) : "N/A";
    const callbacks = Math.floor(property.callbacks / property.completed * 100)
    return <React.Fragment>
      <Card
        className="border border-light col-xs-12 col-md-2 text-center m-4"
        style={{backgroundColor: "#F8F8F8", minWidth: "25%"}}
      >
        <CardBody>
          <CardTitle>Average Rating</CardTitle>
          <h1>{rating}</h1>
          <div style={{position: "relative"}}>
            {stars()}
          </div>
          <div>
            {`${property.rating_count} total`}
          </div>
        </CardBody>
      </Card>
      <Card
        className="border border-light col-xs-12 col-md-2 text-center m-4"
        style={{backgroundColor: "#F8F8F8", minWidth: "25%"}}
      >
        <CardBody>
          <h1>{isNaN(callbacks) ? "N/A" : `${callbacks}%`}</h1>
          <div className="text-warning" style={{position: "relative"}}>
            <strong>Average Callbacks</strong>
          </div>
        </CardBody>
      </Card>
    </React.Fragment>
  }

  setProperty(property){
    actions.fetchAdminSixMonths(property.id).then((r) => {
      const data = r.data[0];
      this.setState({
        propertyData: [...data.stats].reverse(),
        selectedProperty: property.id,
        property: property
      });
    })
  }

  render() {
    const {properties} = this.props;

    if (properties.length == 0) {
      return (
        <p>Loading</p>
      )
    }

    const {selectedProperty, property, propertyData} = this.state;
    return <Row className="mt-1">
      <Col xs={12}>
        <PropertySelect
          properties={properties}
          property={property}
          onChange={this.setProperty.bind(this)}
        />
        {selectedProperty &&
        <Fragment>
          <div className="d-flex justify-content-center">
            {this.rating()}
          </div>
          <Row>
            <Col xl={6} lg={12}>
              <HorizontalBar
                data={barChartData1(propertyData)}
                plugins={[ChartDataLabels]}
                options={{
                  title: {
                    text: "Work Orders",
                    display: true
                  },
                  scales: {
                    xAxes: [{
                      ticks: {
                        beginAtZero: true
                      }
                    }]
                  },
                  plugins: {
                    datalabels: {
                      clamp: true,
                      clip: true,
                      formatter: (value, context) => {
                        if (context.datasetIndex == 1 && value > 0) {
                          return moment.duration(this.state.propertyData[context.dataIndex].average_completion_time, "seconds").humanize()
                        } else if (context.datasetIndex == 0 && value > 0) {
                          return value
                        }
                        return null;
                      }
                    }
                  }
                }}
              />
            </Col>
            <Col xl={6} lg={12}>
              <HorizontalBar
                data={barChartData2(propertyData)}
                options={{
                  title: {
                    display: true,
                    text: "Make Ready"
                  },
                  scales: {
                    xAxes: [{
                      ticks: {
                        beginAtZero: true
                      }
                    }]
                  },
                  plugins: {
                    datalabels: {
                      clamp: true,
                      clip: true
                    }
                  }
                }}
              />
            </Col>
          </Row>
          {selectedProperty && tableData(propertyData)}
        </Fragment>
        }
      </Col>
    </Row>
  }
}

export default connect(({reports, properties}) => {
  return {reports, properties}
})(Synopsis);
