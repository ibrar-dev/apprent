import React from 'react';
import {ComposedChart, CartesianGrid, XAxis, YAxis, Tooltip, Legend, Bar} from 'recharts';
import {ResponsiveContainer} from 'recharts';

class CostChart extends React.Component {
  render() {
    const {property, data} = this.props;
    return <ResponsiveContainer width="100%" height={450}>
      <ComposedChart layout="vertical" data={data}>
        <CartesianGrid strokeDasharray="3 3"/>
        <XAxis type="number" />
        <YAxis type="category" dataKey={property ? 'number' : 'name'} width={80}/>
        <Tooltip/>
        <Legend/>
        <Bar dataKey="cost" fill="#475f78"/>
      </ComposedChart>
    </ResponsiveContainer>
  }
}

export default CostChart;