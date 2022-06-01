import React, {Component} from 'react';
import moment from 'moment';
import actions from "../actions";

class Post extends Component {
  state = {}

  toggleOn(){
    this.setState({...this.state, showDelete: true})
  }
  toggleOff(){
    this.setState({...this.state, showDelete: false})
  }

  delete(){
    confirm("Are you sure you want to delete this post?")
    {
      actions.deletePost(this.props.post.id)
    }
  }

  render() {
    const {post, setPost} = this.props;
    const {showDelete} = this.state;
    return <tr onMouseEnter={this.toggleOn.bind(this)}  onMouseLeave={this.toggleOff.bind(this)}>
      <td></td>
      <td>{post.resident}</td>
      <td>{post.text}</td>
      <td>{moment.utc(post.inserted_at).local().format("MM/DD/YY HH:mm")}</td>
      <td onClick={setPost.bind(this, post)}>{post.likes.length}</td>
      <td onClick={setPost.bind(this, post)}>{post.reports.length}</td>
      <td>{post.visible ? "VISIBLE" : "DELETED"}      {showDelete && post.visible == true ? <i style={{color:"red", fontSize:20}} onClick={this.delete.bind(this)} className="far fa-trash-alt"></i> : <i style={{opacity:0, fontSize:20}} className="far fa-trash-alt"></i>}</td>
    </tr>
  }
}

export default Post;