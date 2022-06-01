import styled, { css } from 'styled-components';

const Wrapper = styled.div`
  display: flex;
  align-items: center;
  padding-left: 16px;
  padding-right: 16px;
  justify-content: space-between;
  height: 43px;
  min-width: 320px;

  border: 1px solid #E3E3E3;
  border-radius: 8px;

  box-shadow: 0px 1px 2px rgba(0, 0, 0, 0.08);

  cursor: pointer;

  &:hover {
    border-color: #B1B1B1;
  }

  ${p => p.active && css`
    border-color: #1DBD6B;
    &:hover {
      border-color: #1DBD6B;
    }  
  `}
`;

export default Wrapper;