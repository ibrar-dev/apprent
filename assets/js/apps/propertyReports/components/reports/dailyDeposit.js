import React, {Component} from 'react';
import {connect} from 'react-redux';
import moment from 'moment';
import {Table, Row, Col} from 'reactstrap';
import {toCurr} from "../../../../utils";

class DailyDeposit extends Component {
  state = {};

  calculatePercentage(high, low) {
    return (low/high) * 100;
  }

  render() {
    const {property, reportData} = this.props;
    if (reportData && reportData.length === 0) return <div />;
    return <React.Fragment>
      <Row>
        <Col>
          <Table className="align-content-center">
            <thead>
              <tr>
                <th colSpan={4} style={{backgroundColor: "#5dbd77", textAlign: 'center', color: 'white'}}>{property.name}</th>
              </tr>
            </thead>
            <tbody>
              <tr style={{textAlign: 'center'}}>
                <td style={{backgroundColor: "#4c9f62"}}>Occupancy</td>
                <td>{this.calculatePercentage(reportData.units_min.length, reportData.occupied_units.length).toFixed(2)}%</td>
                <td style={{backgroundColor: "#4c9f62"}}>Reno Units</td>
                <td>{reportData.down_reno_units.filter(u => u.status === "RENO").length}</td>
              </tr>
              <tr style={{textAlign: 'center'}}>
                <td style={{backgroundColor: "#4c9f62"}}>Leased</td>
                <td>{this.calculatePercentage(reportData.units_min.length, (reportData.units_min.length - reportData.available_units.length)).toFixed(2)}%</td>
                <td style={{backgroundColor: "#4c9f62"}}>Down Units</td>
                <td>{reportData.down_reno_units.filter(u => u.status === "DOWN").length}</td>
              </tr>
              <tr style={{textAlign: 'center'}}>
                <td style={{backgroundColor: "#4c9f62"}}>Trend (30, 60, 120, &#8734;)</td>
                <td>{reportData.trend.thirty.toFixed(2)}%</td>
                <td>{reportData.trend.sixty.toFixed(2)}%</td>
                <td className="d-flex justify-content-between"><span>{reportData.trend.one_twenty.toFixed(2)}%</span><span>{reportData.trend.indefinite.toFixed(2)}%</span></td>
              </tr>
              <tr style={{textAlign: 'center'}}>
                <td style={{backgroundColor: "#4c9f62"}}>Todays Deposits</td>
                <td>{toCurr(reportData.daily)}</td>
                <td style={{backgroundColor: "#4c9f62"}}>MTD Deposits</td>
                <td>{toCurr(reportData.mtd)}</td>
              </tr>
              <tr>
                <th colSpan={4} style={{backgroundColor: "#5dbd77", textAlign: 'center', color: 'white'}}>Leasing Activity Week Of {moment().format("MM/DD/YYYY")}</th>
              </tr>
              <tr>
                <th style={{backgroundColor: "#5dbd77", textAlign: 'center', color: 'white'}} />
                <th style={{backgroundColor: "#5dbd77", textAlign: 'center', color: 'white'}}>
                  Today
                </th>
                <th colSpan={2} style={{backgroundColor: "#5dbd77", textAlign: 'center', color: 'white'}}>
                  Week to date
                </th>
              </tr>
              <tr style={{textAlign: 'center'}}>
                <td style={{backgroundColor: "#4c9f62"}}>Tours</td>
                <td>{reportData.tours}</td>
                <td colSpan={2}>{reportData.wtd_tours}</td>
              </tr>
              <tr style={{textAlign: 'center'}}>
                <td style={{backgroundColor: "#4c9f62"}}>Applications</td>
                <td>{reportData.apps}</td>
                <td colSpan={2}>{reportData.wtd_apps}</td>
              </tr>
              <tr style={{textAlign: 'center'}}>
                <td style={{backgroundColor: "#4c9f62"}}>Declined Applications</td>
                <td>{reportData.declined_apps}</td>
                <td colSpan={2}>{reportData.wtd_declined_apps}</td>
              </tr>
              <tr style={{textAlign: 'center'}}>
                <td style={{backgroundColor: "#4c9f62"}}>New Leases</td>
                <td>{reportData.new_leases}</td>
                <td colSpan={2}>{reportData.wtd_new_leases}</td>
              </tr>
              <tr style={{textAlign: 'center'}}>
                <td style={{backgroundColor: "#4c9f62"}}>Notice Given</td>
                <td>{reportData.ntv}</td>
                <td colSpan={2}>{reportData.wtd_ntv}</td>
              </tr>
              <tr style={{textAlign: 'center'}}>
                <td style={{backgroundColor: "#4c9f62"}}>Move Ins</td>
                <td>{reportData.move_ins}</td>
                <td colSpan={2}>{reportData.wtd_move_ins}</td>
              </tr>
              <tr style={{textAlign: 'center'}}>
                <td style={{backgroundColor: "#4c9f62"}}>Move Outs</td>
                <td>{reportData.move_ins}</td>
                <td colSpan={2}>{reportData.wtd_move_outs}</td>
              </tr>
            </tbody>
          </Table>
        </Col>
      </Row>
    </React.Fragment>
  }
}

export default connect(({property, reportData}) => {
  return {property, reportData}
})(DailyDeposit)