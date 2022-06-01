import React, {useEffect, useRef, useState} from "react";
import styled from "styled-components";
import {DownCaretSvg} from "../../icons";
import Wrapper from "./components/Wrapper";
import Label from "./components/Label";
import ListHeader from "./components/ListHeader";
import SearchBar from "./components/SearchBar";
import ChildrenWrapper from "./components/ChildrenWrapper";

const Filter = (props) => {
  const {
    placeholder,
    label,
    showSearch,
    showListHeader,
    children,
    topList,
    onClear,
    onSelectAll,
    searchValue,
    onSearch,
  } = props;

  const wrapperRef = useRef(null);
  const [active, setIsActive] = useState(false);

  useEffect(() => {
    function handleClickOutside(event) {
      if (wrapperRef.current && !wrapperRef.current.contains(event.target)) {
        setIsActive(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, [wrapperRef]);

  const onChange = (event) => {
    onSearch && onSearch(event.target.value);
  };

  return (
    <div ref={wrapperRef}>
      <Wrapper active={active} onClick={() => setIsActive((val) => !val)}>
        <div className="flex items-center">
          <Label bold className="mr-1">
            {label}
          </Label>
          {(!topList || topList && topList.length < 1)
            ? (
              <Label className="ml-2">
                {placeholder}
              </Label>
            )
            : (
              <div className="flex items-center">
                {topList.length > 2 ? topList.slice(0, 2) : topList}
                {topList.length > 2 && <div>...</div>}
              </div>
            )}
        </div>
        <div className="flex items-center">
          {topList && topList.length > 0
            && (
            <CountWrapper className="mr-2">
              {topList?.length}
            </CountWrapper>
            )}
          <DownCaretSvg />
        </div>
      </Wrapper>
      {active
        && (
        <div className="mt-2 absolute bg-white z-10">
          {
            showListHeader && (
              <ListHeader
                onSelectAll={onSelectAll}
                onClear={onClear}
                count={topList?.length}
              />
            )
          }
          {showSearch && <SearchBar value={searchValue} onChange={onChange} />}
          <ChildrenWrapper hasTop={showListHeader || showSearch}>
            {children}
          </ChildrenWrapper>
        </div>
        )}
    </div>
  );
};

const CountWrapper = styled.div`
  width: 24.14px;
  height: 16.98px;
  background-color: #1DBD6B;
  border-radius: 30px;

  font-style: normal;
  font-weight: 400;
  font-size: 12px;
  line-height: 24px;
  color: #FFFFFF;

  display: flex;
  align-items: center;
  justify-content: center;
`;

export default Filter;
