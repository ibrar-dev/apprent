import React, {useEffect, useRef, useState} from "react";
import styled from "styled-components";

const countSuggestion = [10, 15, 30, 45];

const PageCountDropdown = ({elementsCount, onSelect}) => {
  const [isActive, setIsActive] = useState(false);
  const wrapperRef = useRef(null);

  useEffect(() => {
    function handleClickOutside({target}) {
      if (wrapperRef.current && !wrapperRef.current.contains(target)) {
        setIsActive(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, [wrapperRef]);

  return (
    <div className="relative" ref={wrapperRef}>
      <Wrapper onClick={() => { setIsActive((val) => !val); }}>
        {elementsCount}
        <div className="ml-1 mt-0.5">
          <svg width="8" height="5" viewBox="0 0 8 5" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M6.92053 1.01758L3.92053 4.01758L0.920532 1.01758" stroke="#04333B" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </div>
      </Wrapper>

      {isActive
        && (
        <Content>
          {countSuggestion.map((el) => (
            <PageCountWrapper key={el} selected={el === elementsCount} onClick={() => { onSelect(el); setIsActive(false); }}>
              {el}
            </PageCountWrapper>
          ))}
        </Content>
        )}
    </div>
  );
};

const Wrapper = styled.div`
  display: flex;
  align-items: center;
  justify-content: center;
  width: 46px;
  height: 33px;
  border: 1px solid #EEEEEE;
  border-radius: 8px;
  box-shadow: 0px 1px 2px rgba(0, 0, 0, 0.07);
  color: #04333B;

  cursor: pointer;
`;

const Content = styled.div`
  position: absolute;
  background-color: #f1f1f1;
  width: 46px;
  
  background: #FFFFFF;

  border: 1px solid #E3E3E3;
  box-sizing: border-box;

  box-shadow: 0px 1px 2px rgba(0, 0, 0, 0.08);
  border-radius: 12px;

  z-index: 10;

  font-weight: 400;
  color: #04333B;

  margin-top: 5px;
`;

const PageCountWrapper = styled.div`
  display: flex;
  align-items: center;
  justify-content: center;
  height: 30px;
  cursor: pointer;

  color: ${(p) => (p.selected ? "#1DBD6B" : "#04333B")};
`;

export default PageCountDropdown;
