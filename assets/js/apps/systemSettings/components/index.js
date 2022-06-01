import React from "react";
import { Card } from "antd";
import cardGrid from "./cardGrid";
import listOfUrls from "./listOfUrls";

function systemSettingsApp() {
    return (
        <Card title="Settings" bordered={false}>
            {listOfUrls.map((u, i) => cardGrid(i, u.title, u.url, u.description))}
        </Card>
    )
}

export default systemSettingsApp;