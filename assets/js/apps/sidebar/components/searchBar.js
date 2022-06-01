import React from "react";
import MagnifyingGlassSvg from "../assets/magnifyingGlass";
import device from "../styles/deviceConstants";

const SearchBar = ({value, onChange}) => (
  <div
    style={{
      border: "1px solid #566F75",
      borderRadius: 8,
      display: "flex",
      flexDirection: device.desktopL ? "row-reverse" : "row",
      alignItems: "center",
      height: device.desktopL ? 42 : 37,
      width: "90%",
      marginLeft: "5%",
      paddingLeft: device.desktopL ? 20 : null,
      paddingRight: device.desktopL ? 20 : null,
      svg: {
        marginRight: device.desktopL ? 12 : 8.5,
      },
    }}
  >
    <input
      value={value}
      onChange={onChange}
      placeholder="Quick Search"
      style={{
        backgroundColor: "#04333B",
        borderRadius: 8,
        width: "100%",
        height: "100%",
        outline: "none",
        color: "#F3F5F5",
        fontWeight: 400,
        fontSize: 12,
        background: "transparent",
        paddingLeft: 15,
        border: "none",
        "::placeholder": { /* Chrome, Firefox, Opera, Safari 10.1+ */
          color: "#fff",
          opacity: 1, /* Firefox */
        },
        ":msInputPlaceholder": { /* Internet Explorer 10-11 */
          color: "#fff"
        },
        "::msInputPlaceholder": { /* Microsoft Edge */
          color: "#fff",
        },
      }}
    />
    <MagnifyingGlassSvg color="#F3F5F5" />
  </div>
);

export default SearchBar;
