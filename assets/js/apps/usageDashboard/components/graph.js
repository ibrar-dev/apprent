import React from 'react';
import {Pie} from 'react-chartjs-2';

const colors = ['#F7464A', '#46BFBD', '#FDB45C', '#5D54FF', '#32AF20'];

class Graph extends React.Component {
  render() {
    const {data} = this.props;
    const graphData = {
      datasets: [
        {
          backgroundColor: colors,
          data: data.map(d => d.value)
        },
      ],
      labels: data.map(d => d.label)
    };
    const options = {
      legend: {display: false},
      tooltips: {enabled: false},
      plugins: {
        labels: {
          showZero: false,
          arc: true,
          render: 'label',
          position: 'outside'
        }
      }
    };
    return <Pie data={graphData} options={options}/>;
  }
}

export default Graph;