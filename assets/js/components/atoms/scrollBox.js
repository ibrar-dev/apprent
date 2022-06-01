import React from "react";
import styled from "styled-components";

const ScrollBox = (props) => (
  <Box>
    <Content>
      {props.children}
    </Content>
  </Box>
);

const Box = styled.div`
  overflow: auto;
  visibility: hidden;
  max-height: 100%;
  max-width: 100%;
  padding-right: 10px;
  padding-bottom: 10px;
  
  &:hover {
    visibility: visible;
  }


  /* width */
  ::-webkit-scrollbar {
    width: 4px;
    height: 4px;
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

const Content = styled.div`
  visibility: visible;
  height: 100%;
`;

export default ScrollBox;