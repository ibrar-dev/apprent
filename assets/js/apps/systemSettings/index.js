import React from "react";
import ReactDOM from "react-dom";
import SystemSettingsApp from "./components";

if (document.getElementById("system-settings-app")) {
    ReactDOM.render(
        <SystemSettingsApp />,
        document.getElementById("system-settings-app")
    )
}