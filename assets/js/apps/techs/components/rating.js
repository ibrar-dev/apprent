import React from 'react';

const startStyle = {top: '2px', left: 0, overflow: 'hidden'};

class Star extends React.Component {
  render() {
    const {fill} = this.props;
    const width = fill < 0 ? 0 : (fill > 1 ? '100%' : `${fill * 100}%`);
    return <div className="position-relative d-inline mr-1 text-left" style={{fontSize: '16px'}}>
      <i className="far fa-star text-warning" />
      <i className="fas fa-star position-absolute text-warning" style={{...startStyle, width}} />
    </div>;
  }
}

class Rating extends React.Component {
  render() {
    const {rating} = this.props;
    if (!rating) return <div style={{fontSize: '16px'}}>Not Rated</div>;
    return [...Array(5)].map((undef, num)=> <Star key={num} fill={rating - num} />).concat([' ', rating.toFixed(2)]);
  }
}

export default Rating;