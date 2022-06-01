import React from 'react';
import {Card, CardHeader, CardBody, Row, Col} from 'reactstrap';
import {connect} from 'react-redux';
import {HorizontalBar} from 'react-chartjs-2';
import moment from 'moment';
import Graph from './graph';
import 'chartjs-plugin-labels';
import {toCurr} from '../../../utils';
import colors from './colors';

const options = (title) => {
  return {
    plugins: {
      labels: {
        render: 'label',
      }
    },
    title: {
      display: true,
      text: title,
    }
  };
};

const barChartData = (properties) => {
  let data = {
    labels: [],
    datasets: [{data: [], backgroundColor: [], borderColor: [], label: 'Days', borderWidth: 1}]
  };
  const toDisplay = properties.filter(p => p.average_completion_time > 0);
  toDisplay.forEach((p, i) => {
    const col = colors(i, toDisplay.length);
    data.datasets[0].data.push(moment.duration(p.average_completion_time, 'seconds').asDays().toFixed(2));
    data.datasets[0].backgroundColor.push(col.replace(/, .*\)/, ',0.5)'));
    data.datasets[0].borderColor.push(col);
    data.labels.push(p.name);
  });
  return data;
};

class UsageDashboardApp extends React.Component {

  filterDelivered(packages) {
    return packages ? packages.filter(p => p.status === "Delivered").length : 0;
  }

  filterNewPackages(packages) {
    if (!packages) return 0;
    return packages.filter(p => moment(p.inserted_at).isBetween(moment().subtract(30, 'days'), moment())).length;
  }

  render() {
    const {stats} = this.props;
    const payments = stats.payments || {};
    const collections = stats.collections || {};
    const paymentsData = [
      {label: `Admin - ${payments.admin}`, value: payments.admin},
      {label: `Web - ${payments.web}`, value: payments.web},
      {label: `App - ${payments.app}`, value: payments.app},
    ];
    const collectionData = [
      {label: `Surcharges ${toCurr(collections.surcharges)}`, value: collections.surcharges},
      {label: `Payments ${toCurr(collections.collected)}`, value: collections.collected},
      {label: `Outstanding ${toCurr(collections.outstanding)}`, value: collections.outstanding},
    ];
    const packagesData = [
      {label: `Received - ${this.filterNewPackages(stats.packages)}`, value: this.filterNewPackages(stats.packages)},
      {label: `Delivered - ${this.filterDelivered(stats.packages)}`, value: this.filterDelivered(stats.packages)}
    ];
    const prospectData = [
      {label: `Applications - ${stats.applications}`, value: stats.applications},
      {label: `Office Applications - ${stats.in_house_applications}`, value: stats.in_house_applications},
      {label: `Tours - ${stats.showings}`, value: stats.showings},
      {label: `Prospects - ${stats.prospects}`, value: stats.prospects},
    ];

    return <Card>
          <CardHeader>Usage over the last 30 days</CardHeader>
          <CardBody>
            <Row className="mb-3">
              <Col>
                <Card className="m-0">
                  <CardBody className="text-center">
                    <Graph data={paymentsData}/>
                    <h3>{payments.admin + payments.web + payments.app} Payments Made</h3>
                  </CardBody>
                </Card>
              </Col>
              <Col>
                <Card className="m-0">
                  <CardBody className="text-center">
                    <Graph data={collectionData}/>
                    <h3>
                      {toCurr(parseFloat(collections.surcharges) +
                        parseFloat(collections.collected) +
                        parseFloat(collections.outstanding))} Payments
                    </h3>
                  </CardBody>
                </Card>
              </Col>
            </Row>
            <Row>
              <Col>
                <Card>
                  <CardBody className="text-center">
                    <div>User Sign Ins</div>
                    <h3 className="m-0">{stats.logins}</h3>
                  </CardBody>
                </Card>
              </Col>
              <Col>
                <Card>
                  <CardBody className="text-center">
                    <div>Payment Sources Added</div>
                    <h3 className="m-0">{stats.payment_sources}</h3>
                  </CardBody>
                </Card>
              </Col>
            </Row>
            <Row>
              <Col className="pb-3">
                {stats.maint_history &&
                <HorizontalBar data={barChartData(stats.maint_history)}
                               options={
                                 {legend: {display: false}, ...options("Average Completion Time (days)")}
                               }/>}
              </Col>
            </Row>
            <Row>
              <Col>
                <Card>
                  <CardBody className="text-center">
                    <div>Work Orders Created</div>
                    <h3 className="m-0">{stats.work_orders}</h3>
                  </CardBody>
                </Card>
              </Col>
              <Col>
                <Card>
                  <CardBody className="text-center">
                    <div>Work Orders Completed</div>
                    <h3 className="m-0">{stats.work_orders_completed}</h3>
                  </CardBody>
                </Card>
              </Col>
            </Row>
            <Row>
              <Col>
                <Card>
                  <CardBody className="text-center">
                    <Graph data={prospectData}/>
                    <h3>New Peeps</h3>
                  </CardBody>
                </Card>
              </Col>
              <Col>
                <Card>
                  <CardBody className="text-center">
                    <Graph data={packagesData}/>
                    <h3>Packages</h3>
                  </CardBody>
                </Card>
              </Col>
            </Row>
          </CardBody>
        </Card>;
  }
}

export default connect(({stats, properties}) => {
  return {stats, properties};
})(UsageDashboardApp);
