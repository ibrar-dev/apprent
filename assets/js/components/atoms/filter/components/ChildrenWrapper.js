import styled, {css} from "styled-components";

const ChildrenWrapper = styled.div`
  max-height: 300px;
  min-width: 320px;

  border: 1px solid #E3E3E3;
  border-radius: 8px;

  overflow-y: auto;

  ${(p) => p.hasTop && css`
    border-top-width: 0px;
    border-radius: 0px 0px 8px 8px;
  `}

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

export default ChildrenWrapper;
