import React from 'react';
import {connect} from 'react-redux';
import Integration from './integration';

const availableIntegrations = [
  {provider: "KyckGlobal", fields: ["email", "password", "payer_id"]},
  {provider: "SoftLedger", fields: ["grant_type", "audience", "client_id", "client_secret", "tenantUUID"]},
  {provider: "Twilio", fields: ["sid", "token", "phone_from", "url"]},
  {provider: "Zendesk", fields: ["subdomain", "user", "api_token"]},
  {provider: "Tenantsafe", fields: ["postback"]},
  {
    provider: "Yardi", fields: [
      "username",
      "password",
      "platform",
      "server_name",
      "db",
      "url",
      "entity",
      "interface",
      "gl_account"
    ]
  }
]

class CredentialSets extends React.Component {
  render() {
    const {credentialSets} = this.props;
    if (credentialSets === 'not loaded') return <div/>
    return availableIntegrations.map((integration) => {
      const set = credentialSets.find(set => set.provider === integration.provider)
      const defaultSet = {credentials: [], provider: integration.provider}
      return <Integration key={integration.provider} integration={integration} set={set || defaultSet}/>
    })
  }
}

export default connect(({credentialSets}) => {
  return {credentialSets};
})(CredentialSets);