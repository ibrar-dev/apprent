import listOfUrls from "../systemSettings/components/listOfUrls";

function condenseList(list) {
  return list.reduce((acc, item) => `${acc} ${item.title} ${item.description} ${item.url}`, "")
}

const tags = {
  property_reports: 'Daily Deposit Rent Roll Collections Move Out Delinquency Availability Box Score',
  maintenance_reports: 'Orders Cost Property Maintenance Report Unit Category Techs Supervisors Completed Open Kat Make Readies Daily Report Analytics',
  budget_tags: 'Budgets Accrual How Much Money Do I have Left',
  property_settings: 'Floor Plans Integrations API Keys Showing Hours Tours Openings Features',
  system_settings: condenseList(listOfUrls)
};

export default tags;