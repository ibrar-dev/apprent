import device from "../../../components/atoms/utils/device";
import styled, { css } from 'styled-components';

const Wrapper = styled.div`
  display: flex;
  padding: 5px;
  padding-top: 0px;
  padding-bottom: 0px;
  margin-right: 10px;
  margin-left: 10px;
  
  ${p => p.withoutHeader && css`
    margin-top: 0px;
    &:before {
      content: "";
      position: fixed;
      z-index: 2;
      background-color: transparent;
      top: 5px;
      margin-left: 5px;
      margin-right: 5px;
      left: 0px;
      height: 50px;
      width: calc(100% - 10px);
      border-top-left-radius: 30px;
      border-top-right-radius: 30px;
      box-shadow: 0 -15px 0 7px #04333B;
      pointer-events: none;
    }
  `}

  @media ${device.tablet} {
    margin-top: 0px;
    height: 100vh;
    padding: 10px;
    padding-left: 0px;
    margin-right: 10px;
    margin-left: 10px;
  }
`;

export default Wrapper;