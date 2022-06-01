import React, {forwardRef, useImperativeHandle, useRef} from "react";
import styled from "styled-components";
import PageCountDropdown from "./components/PageCountDropdown";
import PagesNavigator from "./components/PagesNavigator";
import device from "../utils/device";

const Table = forwardRef((props, ref) => {
  const {
    headerRow,
    tableRows,
    totalItemsCount,
    onChangePageSize,
    onChangePage,
    pagination: {currentPage, pageSize},
  } = props;

  const tbodyRef = useRef(null);

  useImperativeHandle(ref, () => ({
    scrollToTop() {
      if (tbodyRef && tbodyRef.current) {
        tbodyRef.current.scrollTo({top: 0, left: 0, behavior: "smooth"});
      }
    },
  }));

  return (
    <div>
      <TableWrapper ref={tbodyRef}>
        <Tbl>
          <thead>
            {headerRow}
          </thead>
          <tbody>
            {tableRows}
          </tbody>
        </Tbl>
      </TableWrapper>
      <Footer className="mt-4 mb-10">
        <div>
          <PagesNavigator
            pagesCount={Math.ceil(totalItemsCount / pageSize)}
            onSelect={onChangePage}
            currentPage={currentPage}
          />
        </div>
        <div className="flex items-center">
          <div>View</div>
          <div className="mx-1.5">
            <PageCountDropdown
              onSelect={onChangePageSize}
              elementsCount={pageSize}
            />
          </div>
          <div>items per page</div>
        </div>
        <div>
          {" "}
          {((currentPage - 1) * pageSize) + 1}
          {" "}
          -
          {" "}
          {((currentPage - 1) * pageSize + tableRows.length)}
          {" "}
          out of
          {" "}
          {totalItemsCount}
          {" "}
          items
        </div>
      </Footer>
    </div>
  );
});

const TableWrapper = styled.div`

  @media ${device.tablet} {

    max-width: calc(100vw - 230px);
    max-height: calc(100vh - 300px);
    overflow: auto;
    
    ::-webkit-scrollbar {
      width: 5px;
      height: 5px;
    }
    
    /* Track */
    ::-webkit-scrollbar-track {
      box-shadow: inset 0 0 1px grey; 
      border-radius: 1px;
    }
    
    /* Handle */
    ::-webkit-scrollbar-thumb {
      background: #A5E5C4; 
      border-radius: 2px;
    }
    
    /* Handle on hover */
    ::-webkit-scrollbar-thumb:hover {
      background: #1DBD6B; 
    }
  }
`;

const Tbl = styled.table`
  width: 100%;

  @media ${device.tablet} {
    thead, tbody tr {
      width: 100%;
    }

    thead th {
      position: sticky;
      top: 0;
      z-index: 1;
      background: white;
    }

    thead th:first-child {
      position: sticky;
      left: 0;
      background: white;
      z-index: 2;
    }

    tbody th {
      position: sticky;
      left: 0;
      background: white;
      z-index: 1;
    }
  }
`;

const Footer = styled.div`
  display: none;

  @media ${device.tablet} {
    display: flex;
    align-items: center;
    justify-content: space-between;
    font-weight: 500;
    font-size: 12px;
    color: #334D6E;
  }
`;

export default Table;
