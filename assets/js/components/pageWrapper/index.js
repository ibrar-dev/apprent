import React from "react";
import styled from "styled-components";
import getIsMobile from "../atoms/utils/getIsMobile";
import {Main, MobileHeader, Wrapper} from "./components";

const isMobile = getIsMobile();

const PageWrapper = (props) => {
  if (isMobile) return <PageWrapperMobile {...props} />;
  return <PageWrapperDesktop {...props} />;
};

const PageWrapperMobile = ({children, withoutHeader}) => (
  <Wrapper withoutHeader={withoutHeader}>
    <div className="w-full h-full">
      {!withoutHeader
          && <MobileHeader onMenuToggle={() => { }} />}
      <Main>
        {children}
      </Main>
    </div>
  </Wrapper>
);

const PageWrapperDesktop = ({children}) => (
  <Wrapper>
    <Main>
      <ChildrenWrapperDesktop>
        {children}
      </ChildrenWrapperDesktop>
    </Main>
  </Wrapper>
);

const ChildrenWrapperDesktop = styled.div`
  position: relative;
  overflow-x: hidden;
  max-width: 1564px;
  width: 100%;
  height: 100%;

  /* width */
  ::-webkit-scrollbar {
    width: 4px;
  }

  /* Track */
  ::-webkit-scrollbar-track {
    border-radius: 10px;
  }
  
  /* Handle */
  ::-webkit-scrollbar-thumb {
    background: #A5E5C4; 
  }

  /* Handle on hover */
  ::-webkit-scrollbar-thumb:hover {
    background: #A5E5C4; 
  }
`;

export default PageWrapper;
