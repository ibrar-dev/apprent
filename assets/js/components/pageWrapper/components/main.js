import styled from "styled-components";
import device from "../../../components/atoms/utils/device";

const Main = styled.div`
  background-color: white;
  width: 100%;
  overflow-y: auto;
  min-height: 100vh;

  padding-bottom: 80px;

  @media ${device.tablet} {
    padding: 0px;
    height: 100%;
    min-height: unset;

    position: relative;

    border-radius: 36px;
    display: flex;  
    justify-content: center;

     /* width */
    ::-webkit-scrollbar {
      width: 4px;
    }

    /* Track */
    ::-webkit-scrollbar-track {
      border-radius: 10px;
      margin-right: 20px;
    }
    
    /* Handle */
    ::-webkit-scrollbar-thumb {
      background: #1DBD6B; 
    }

    /* Handle on hover */
    ::-webkit-scrollbar-thumb:hover {
      background: #b30000; 
    }
  }
`;

export default Main;