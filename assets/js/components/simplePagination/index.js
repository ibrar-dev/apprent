import React from 'react';
import Table from './table';
import {Card, Pagination, PaginationItem, PaginationLink, Row, Col} from 'reactstrap';
class Pagination_ extends React.Component {
  state = {page: 1, perPage: 20, lowerLimit:0, upperLimit: 5};

  change(e) {
    this.setState({...this.state, [e.target.name]: parseInt(e.target.value)});
  }

  setSortingFunc(func) {
    this.setState({...this.state, sortingFunc: func});
  }

  sortedCollection() {
    const {sortingFunc} = this.state;
    const {collection} = this.props;
    if (sortingFunc) collection.sort(sortingFunc);
    return collection;
  }

  body() {
    const {type} = this.props;
    switch (type) {
      case 'list':
        return List;
      default:
        return Table;
    }
  }

    getPage(d) {
        const {lowerLimit, upperLimit} = this.state;
        this.setState({...this.state, upperLimit: upperLimit + (d*4), lowerLimit: lowerLimit + (d*4)});
    }

    setPage(page) {
        let {lowerLimit, upperLimit} = this.state;
        lowerLimit = page - 2;
        upperLimit = page + 2;
        if(lowerLimit <= 0){
           upperLimit -= (lowerLimit -1)
           lowerLimit = 0;
        }
        else{
            lowerLimit = page - 3;
        }
        this.setState({...this.state, page, upperLimit: upperLimit, lowerLimit: lowerLimit });

    }

  render() {
    const {perPage, page, lowerLimit, upperLimit} = this.state;
    const {title, component: Component, field, headers, additionalProps, filters, toggleIndex, tableClasses, keyFunc} = this.props;
    const collection = this.sortedCollection();
    const startIndex = perPage * (page - 1);
    const toRender = collection.slice(startIndex, startIndex + perPage);
    const list = toRender.map((c, index) => {
      const props = {[field]: c};
      let componentKey = toggleIndex ? index : c.id || index;
      if (keyFunc) componentKey = keyFunc(c);
      return <Component key={componentKey} index={index} {...props} {...additionalProps} index={index} />;
    });
    const Body = this.body();
      const pages = [...Array(Math.ceil(collection.length / 20))];
    return <Card style={{borderWidth:"0px"}}>
      <div className="card-header d-flex align-items-center justify-content-between" style={{backgroundColor:"white", borderWidth:"0px", paddingBottom:"0px"}}>
          <div className="d-flex" style={{width:"100%"}}>
              <Col style={{paddingLeft:"2.5%"}}>
                  <Row>
                      <Pagination  className="ml-3 b-0" style={{marginBottom: 0}}>
                          <PaginationItem disabled={page === 1}>
                              <PaginationLink previous onClick={this.setPage.bind(this, page - 1)}/>
                          </PaginationItem>
                          {pages.map((p, index) => ((index >= lowerLimit && index < upperLimit) &&
                              <PaginationItem key={index} >
                                  <Row>
                                      <Col>
                                          <PaginationLink onClick={this.setPage.bind(this, index + 1)} style={page === index + 1 ? {backgroundColor:"#3a3b42", borderColor:"#3a3b42", color:"white"}:{}}>
                                              {index + 1}
                                          </PaginationLink>
                                      </Col>
                                  </Row>
                              </PaginationItem>
                          ))}
                          <PaginationItem disabled={page === pages.length}>
                              <PaginationLink next onClick={this.setPage.bind(this, page + 1)}/>
                          </PaginationItem>
                      </Pagination>
                      {/*<div className="d-flex align-items-center" style={{width: '180px', marginLeft: "10px",color:"#7b7b7b"}}>Showing {startIndex + 1} to {startIndex + perPage} of {collection.length}</div>*/}
                  </Row>
              </Col>
              <Col>
              <div className="d-flex  justify-content-end" style={{flex: '0 70%'}}>
                  <div className="mr-3 b-0" style={{width:"80%"}}>
                      {filters}
                  </div>
              </div>
              </Col>
            <Col className="d-flex align-items-center">
              <div className="d-flex  justify-content-end" style={{width:"100%"}}>
                <h5 style={{color: '#a7adb5', marginBottom:0}}>
                  {title}
                </h5>
              </div>
            </Col>
          </div>
      </div>
      <div className="card-body" style={{paddingTop:"0px"}}>
        <Body list={list} headers={headers} parent={this} tableClasses={tableClasses}/>
      </div>
    </Card>;
  }
}

export default Pagination_;
