import React from 'react';
import {ComposedChart, CartesianGrid, XAxis, YAxis, Tooltip, Legend, Bar} from 'recharts';
import {ResponsiveContainer} from 'recharts';

class OrdersChart extends React.Component {
  render() {
    const {property} = this.props;
    return <ResponsiveContainer width="100%" height={450}>
      <ComposedChart layout="vertical" data={this.props.data}>
        <CartesianGrid strokeDasharray="3 3"/>
        <XAxis type="number" />
        <YAxis type="category" dataKey={property ? 'number' : 'name'} width={80}/>
        <Tooltip/>
        <Legend/>
        <Bar dataKey="orders" fill="#475f78"/>
        <Bar dataKey="completed" fill="#82ca9d"/>
        <Bar dataKey="callbacks" fill="#ff1122"/>
      </ComposedChart>
    </ResponsiveContainer>
  }
}

export default OrdersChart;