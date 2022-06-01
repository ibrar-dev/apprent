import React from 'react';
import Table from './table';
import Menu from './menu';
import Rows from './row';
import {
  Button,
  Pagination,
  PaginationItem,
  PaginationLink,
  Row,
  Col,
  ListGroup,
  ListGroupItem,
  Collapse
} from 'reactstrap';

class Pagination_ extends React.Component {
  state = {page: 1, perPage: 60, lowerLimit: 0, upperLimit: 5};

  change(e) {
    this.setState({[e.target.name]: parseInt(e.target.value)});
  }

  changePerPage(perPage) {
    this.setState({perPage});
  }

  changePage(page) {
    this.setState({page});
  }

  setSortingFunc(sortingFunc) {
    this.setState({sortingFunc});
  }

  sortedCollection() {
    const {sortingFunc} = this.state;
    const {collection} = this.props;
    if (sortingFunc) collection.sort(sortingFunc);
    return collection;
  }

  getPage(d) {
    const {lowerLimit, upperLimit} = this.state;
    this.setState({...this.state, upperLimit: upperLimit + (d * 4), lowerLimit: lowerLimit + (d * 4)});
  }

  setPage(page) {
    let lowerLimit = page - 2;
    let upperLimit = page + 2;
    if (lowerLimit <= 0) {
      upperLimit -= (lowerLimit - 1);
      lowerLimit = 0;
    } else {
      lowerLimit = page - 3;
    }
    this.setState({...this.state, page, upperLimit: upperLimit, lowerLimit: lowerLimit});

  }

  body() {
    const {type} = this.props;
    switch (type) {
      case 'row':
        return Rows;
      case 'list':
        return List;
      default:
        return Table;
    }
  }

  togglePagePopover() {
    this.setState({...this.state, pagesPopoverOpen: !this.state.pagesPopoverOpen});
  }

  render() {
    const {perPage, page, lowerLimit, upperLimit, pagesPopoverOpen} = this.state;
    const {
      toggleIndex,
      title,
      component: Component,
      field,
      headers,
      additionalProps,
      filters,
      className,
      menu,
      headerClassName,
      tableClasses,
      keyFunc,
      totalRow,
      hidePerPage,
    } = this.props;
    const collection = this.sortedCollection();
    const startIndex = perPage * (page - 1);
    const toRender = perPage === "All" ? collection : collection.slice(startIndex, startIndex + perPage);
    const list = toRender.map((c, index) => {
      const props = {[field]: c};
      let componentKey = toggleIndex ? index : c.id || index;
      if (keyFunc) componentKey = keyFunc(c);
      return <Component key={componentKey} {...props} {...additionalProps}  />;
    });
    const Body = this.body();
    const pages = perPage === "All" ? [0] : [...Array(Math.ceil(collection.length / perPage))];
    return <div className={"card " + className}>
      <div className={"card-header " + (headerClassName || '')}>
        <Row>
          <Col className="d-flex align-items-center">{title}</Col>
          <Col className="d-flex align-items-center">
            <div className="flex-auto d-flex justify-content-end">
              {filters}
            </div>
            {
              collection.length > perPage
              && (
                <Pagination className="ml-1 b-0" style={{marginBottom: 0, borderLeft: 'solid thin #e4e6eb'}}>
                    <PaginationItem disabled={page === 1}>
                      <PaginationLink previous style={{
                        backgroundColor: '#f6f6f6',
                        fontWeight: 'bold',
                        border: "none",
                        fontSize: 22,
                        paddingTop: 0,
                        paddingBottom: 0
                      }} onClick={this.setPage.bind(this, page - 1)}/>
                    </PaginationItem>
                    {pages.map((p, index) => ((index >= lowerLimit && index < upperLimit) &&
                      <PaginationItem key={index}>
                        <Row>
                          <Col>
                            <PaginationLink onClick={this.setPage.bind(this, index + 1)} active={index + 1}
                                            style={page === index + 1 ? {
                                              backgroundColor: '#3a3b42',
                                              borderColor: "#3a3b42",
                                              color: 'white',
                                              fontWeight: 'bold',
                                              fontSize: 11
                                            } : {
                                              backgroundColor: '#f6f6f6',
                                              marginLeft: 0,
                                              color: "#a6abb5",
                                              border: "none"
                                            }}>
                              {index + 1}
                            </PaginationLink>
                          </Col>
                        </Row>
                      </PaginationItem>
                    ))}
                    <PaginationItem disabled={page === pages.length}>
                      <PaginationLink style={{
                        backgroundColor: '#f6f6f6',
                        fontWeight: 'bold',
                        border: "none",
                        fontSize: 22,
                        paddingTop: 0,
                        paddingBottom: 0,
                        marginLeft: 0
                      }} next onClick={this.setPage.bind(this, page + 1)}/>
                    </PaginationItem>
                  </Pagination>
              )
            }
            {
              (!hidePerPage || collection.length > 60) && (
                  <div id="pagesPopover">
                    <Button className="btn-outline-muted" outline style={{height: 35}}
                            onClick={this.togglePagePopover.bind(this)}>
                      <div className="d-flex"><small> <b>{collection.length}</b> results </small></div>
                      <i className="fas fa-angle-down" style={{position: "relative", top: -7}}/>
                    </Button>
                    <Collapse isOpen={pagesPopoverOpen} style={{border: "none", position: "absolute", zIndex: 4}}>
                      <ListGroup style={{backgroundColor: '#f6f6f6'}}>
                        {[20, 40, 60, 80, 100, 'All'].map(val => {
                          return <ListGroupItem key={val} tag="button" active={perPage === val}
                                                style={{border: 'none', fontSize: 12, backgroundColor: '#f6f6f6'}}
                                                onClick={this.changePerPage.bind(this, val)}>
                            {val}{val !== 'All' && '/page'}
                          </ListGroupItem>
                        })}
                      </ListGroup>
                    </Collapse>
                  </div>
              )
            }
            {menu && <div><Menu items={menu}/></div>}
          </Col>
        </Row>
      </div>
      <div className="card-body pl-2 pr-2 pt-0">
        <Body list={list} headers={headers} totalRow={totalRow} tableClasses={tableClasses} parent={this}/>
      </div>
    </div>;
  }
}

export default Pagination_;
