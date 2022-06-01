import React from "react"

class Notification extends React.Component{
  _truncate(body, length){
    let suffix = '';
    if(body.length > length) suffix = '...';
    return body.substr(0,length) + suffix;
  }
  render(){
    return (
      <div>
        <h5>{this._truncate(this.props.subject, 20)}</h5>
        <p>{this._truncate(this.props.body, 45)}</p>
      </div>
    )
  }
}

export default Notification