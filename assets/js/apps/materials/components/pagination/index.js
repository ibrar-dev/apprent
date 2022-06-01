import React from 'react';
import Table from './table';
import {Card, Pagination, PaginationItem, PaginationLink, Row, Col} from 'reactstrap';

class Pagination_ extends React.Component {
  state = {page: 1, perPage: 50, lowerLimit:0, upperLimit: 5};

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
        let lowerLimit = page - 2;
        let upperLimit = page + 2;
        if(lowerLimit <= 0){
           upperLimit -= (lowerLimit -1);
           lowerLimit = 0;
        }
        else{
            lowerLimit = page - 3;
        }
        this.setState({...this.state, page, upperLimit: upperLimit, lowerLimit: lowerLimit });

    }

  render() {
    const {perPage, page, lowerLimit, upperLimit} = this.state;
    const {component: Component, field, headers, additionalProps, filters} = this.props;
    const collection = this.sortedCollection();
    const startIndex = perPage * (page - 1);
    const toRender = collection.slice(startIndex, startIndex + perPage);
    const list = toRender.map((c, index) => {
      const props = {[field]: c};
      return <Component key={c.id || index} {...props} {...additionalProps} index={index} />;
    });
    const Body = this.body();
      const pages = [...Array(Math.ceil(collection.length / 50))];
    return <Card style={{borderWidth:"0px"}}>
      <div className="card-header d-flex align-items-center justify-content-between" style={{backgroundColor:"white", borderWidth:"0px", paddingBottom:"0px"}}>
          <Row style={{width:"100%"}}>
              <Col style={{paddingLeft:"2.5%"}}>
                  <Row>
                      <Pagination>
                          <PaginationItem disabled={page === 1}>
                              <PaginationLink previous onClick={this.setPage.bind(this, page - 1)}/>
                          </PaginationItem>
                          {pages.map((p, index) => ((index >= lowerLimit && index < upperLimit) &&
                              <PaginationItem key={index} >
                                  <Row>
                                      <Col>
                                          <PaginationLink onClick={this.setPage.bind(this, index + 1)} style={page === index + 1 ? {backgroundColor:"#87bc4b", borderColor:"#87bc4b", color:"white"}:{}}>
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
                  </Row>
              </Col>
              <Col>
      <div className="d-flex  justify-content-end" style={{flex: '0 70%'}}>
          <div className="mr-3" style={{width:"80%"}}>
              {filters}
          </div>
      </div>
              </Col>
          </Row>
      </div>
      <div className="card-body" style={{paddingTop:"0px"}}>
        <Body list={list} headers={headers} parent={this} />
      </div>
    </Card>;
  }
}

export default Pagination_;