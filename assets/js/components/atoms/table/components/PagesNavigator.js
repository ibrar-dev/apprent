import React from "react";

const PagesNavigator = ({onSelect, currentPage, pagesCount}) => {
  const goToNextPage = () => {
    if (currentPage < pagesCount) onSelect(currentPage + 1);
  };

  const goToPrevPage = () => {
    if (currentPage > 1) onSelect(currentPage - 1);
  };

  const goToFirstPage = () => {
    if (currentPage > 1) onSelect(1);
  };

  const goToLastPage = () => {
    if (currentPage < pagesCount) onSelect(pagesCount);
  };

  return (
    <div className="flex items-center">
      <div className={`mr-2.5 ${currentPage !== 1 ? "cursor-pointer" : null}`}>
        <svg onClick={goToFirstPage} width="8" height="8" viewBox="0 0 8 8" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M7.4375 6.52734L4.4375 3.52734L7.4375 0.527344" stroke={currentPage === 1 ? "#334D6E" : "#1DBD6B"} strokeLinecap="round" strokeLinejoin="round" />
          <path d="M4 6.52734L1 3.52734L4 0.527344" stroke={currentPage === 1 ? "#334D6E" : "#1DBD6B"} strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      </div>
      <div className={`mr-3 ${currentPage !== 1 ? "cursor-pointer" : null}`}>
        <svg onClick={goToPrevPage} width="5" height="8" viewBox="0 0 5 8" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M4.49072 6.83984L1.49072 3.83984L4.49072 0.839844" stroke={currentPage === 1 ? "#334D6E" : "#1DBD6B"} strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      </div>
      <div className="flex items-center">
        Page:
        {" "}
        {currentPage}
        {" "}
        /
        {" "}
        {pagesCount}
      </div>
      <div className={`ml-2 ${currentPage !== pagesCount ? "cursor-pointer" : null}`}>
        <svg onClick={goToNextPage} width="5" height="8" viewBox="0 0 5 8" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M0.6875 0.839844L3.6875 3.83984L0.6875 6.83984" stroke={currentPage === pagesCount ? "#334D6E" : "#1DBD6B"} strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      </div>
      <div className={`ml-2.5 ${currentPage !== pagesCount ? "cursor-pointer" : null}`}>
        <svg onClick={goToLastPage} width="8" height="8" viewBox="0 0 8 8" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M0.5 0.839844L3.5 3.83984L0.5 6.83984" stroke={currentPage === pagesCount ? "#334D6E" : "#1DBD6B"} strokeLinecap="round" strokeLinejoin="round" />
          <path d="M3.9375 0.839844L6.9375 3.83984L3.9375 6.83984" stroke={currentPage === pagesCount ? "#334D6E" : "#1DBD6B"} strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      </div>
    </div>
  );
};

export default PagesNavigator;
