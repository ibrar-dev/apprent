import React from 'react';
import {connect} from 'react-redux';
import {CardHeader, CardBody, Button, ButtonGroup} from 'reactstrap';
import Dashboard from './charts/dashboard';
import TechChart from './charts/techChart';
import SupervisorChart from './charts/supervisorChart';
import DailyReport from './dailyReport';
import Synopsis from './charts/synopsisChart';
import PropertyMetrics from './charts/propertyMetrics';
import UnitsChart from './charts/unitsChart';
import CategoryChart from './charts/categoryChart';
import canEdit from '../../../components/canEdit';
import moment from 'moment';
import actions from '../actions';

class ReportsApp extends React.Component {
  constructor(props) {
    super(props)
    this.state = {reports: [], mode: 'dashboard'}
  }

  componentWillMount() {
    actions.fetchMaintenanceTechs();
  }

  componentWillReceiveProps(props) {
    const propertyList = props.reports.map(p => p.id);
    this.setState({reports: props.reports, propertyList});
  }

  changeMode = (e) => {
    this.setState({mode: e});
  }

  toggleDailyReport = () => {
    this.setState({dailyReport: !this.state.dailyReport});
  }

  /**
   * techs - array of primary key IDs of techs
   * startDate - timestamp
   * endDate - timestamp
   * selectedProperties - array of primary IDs of properties
   */
  fetchDetailedTechInfo = (techs, startDate, endDate, selectedProperties) => {
    actions.fetchMaintenanceTechsInfo(
      techs,
      moment(startDate).format("YYYY-MM-DD"),
      moment(endDate).format("YYYY-MM-DD"),
      selectedProperties
    )
  }

  render() {
    const {maintenanceTechs} = this.props;
    const {reports, propertyList, mode, property, dailyReport} = this.state;
    const data = [];
    ((property && property.units) || reports).forEach(p => {
      if (property || propertyList.includes(p.id)) {
        const cost = p.materials.reduce((sum, m) => sum + m.reduce((s, t) => s + t.cost, 0), 0);
        data.push({...p, cost});
      }
    });
    return (
      <>
      <CardHeader className="d-flex justify-content-between">
        <div className="d-flex align-items-center">
          <ButtonGroup className="ml-1">
            <Button
              outline
              size="sm"
              active={mode === 'dashboard'}
              onClick={() => this.changeMode('dashboard')}
              color="info"
            >
              Dashboard
            </Button>
            <Button
              outline
              size="sm"
              active={mode === 'property'}
              onClick={() => this.changeMode('property')}
              color="info"
            >
              Property Metrics
            </Button>
            <Button
              outline
              size="sm"
              active={mode === 'unit'}
              onClick={() => this.changeMode('unit')}
              color="info"
            >
              Unit Breakdown
            </Button>
            <Button
              outline
              size="sm"
              active={mode === 'synopsis'}
              onClick={() => this.changeMode('synopsis')}
              color="info"
            >
              Synopsis
            </Button>
            {
              canEdit(["Super Admin", "Regional", "Accountant", "Tech"]) &&
                <Button
                  outline
                  size="sm"
                  active={mode === 'tech'}
                  onClick={() => this.changeMode('tech')}
                  color="info"
                >
                  Tech Performance
                </Button>
            }
          </ButtonGroup>
        </div>
        <div>
          <Button
            className='m-0 ml-2'
            color='dark'
            outline size='sm'
            onClick={() => window.print()}
          >
            <i className={`far fa-file-pdf`} />
          </Button>
        </div>
      </CardHeader>
      <CardBody>
        {property && <h3>Viewing {property.name}</h3>}
        {
          mode === 'dashboard' && <Dashboard />
        }
        {
          mode === 'supervisor' && <SupervisorChart />
        }
        {
          mode === 'property' && <PropertyMetrics />
        }
        {
          mode === 'synopsis' && <Synopsis />
        }
        {
          mode === 'unit' && <UnitsChart unitList={propertyList} />
        }
        {
          mode === 'category' && <CategoryChart />
        }
        {
          mode === 'tech' &&
            <TechChart
              maintenanceTechs={maintenanceTechs}
              updateInfo={this.fetchDetailedTechInfo}
            />
        }
      </CardBody>
      <DailyReport
        toggle={() => this.toggleDailyReport()}
        isOpen={dailyReport}
      />
      </>
    )
  }
}

export default connect(({reports, maintenanceTechs,units}) => (
  {reports, maintenanceTechs, units}
))(ReportsApp);
