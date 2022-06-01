import React, {Component} from 'react';
import {Col, Button} from 'reactstrap';
import Lightbox from 'react-image-lightbox';
import actions from '../actions';
class Attachments extends Component {
  state = {
    photoIndex: 0,
    isOpen: false
  }

  static getDerivedStateFromProps(props, state) {
    if (props.attachments.length) {
      let images = props.attachments.filter(a => a.content_type.includes("image"));
      let others = props.attachments.filter(a => !a.content_type.includes("image"));
      return {images: images, others: others}
    }
    return {images: [], others: []}
  }

  displayImageOrIcon(a) {
    if (a.content_type === "application/pdf") return <a href={a.url} target="_blank" className="img-thumbnail"><i className="far fa-file-pdf fa-5x" /></a>;
    // if (a.content_type.includes("video")) return <div className="embed-responsive "><iframe src={a.url} className="embed-responsive-item" allowFullScreen frameborder="0"></iframe></div>;
    return <a href={a.url} target="_blank"><i className="far fa-question-circle fa-5x" /></a>
  }

  openImage(i) {
    this.setState({...this.state, photoIndex: i, isOpen: true})
  }

  closeLightbox() {
    this.setState({isOpen: false})
  }

  deleteAttachment(id){
    actions.deleteAttachment(id, this.props.approval.id)
  }

  render() {
    const {images, photoIndex, isOpen, others} = this.state;
    const {editPage} = this.props;
    return <Col className="d-flex justify-content-around mt-3">
      {others.length ? others.map(a => {
        return <div key={a.id} className="grid-img d-flex flex-column flex-content-center">
          {this.displayImageOrIcon(a)}
          <small>{a.filename}</small>
          {editPage && <Button onClick={this.deleteAttachment.bind(this, a.id)}>delete</Button>}
        </div>
      }) : ""}
      {images.length ? images.map((a, i) => {
        return <div key={a.id} onClick={this.openImage.bind(this, i)} className="grid-img d-flex flex-column flex-content-center">
          <img src={a.url} className="img-fluid img-thumbnail grid-img" alt=""/>
          <small>{a.filename}</small>
          {editPage && <Button onClick={this.deleteAttachment.bind(this, a.id)}>delete</Button>}
        </div>
      }) : ""}
      {isOpen && <Lightbox mainSrc={images[photoIndex] && images[photoIndex].url}
                           onCloseRequest={this.closeLightbox.bind(this)}/>}
    </Col>
  }
}

export default Attachments;
