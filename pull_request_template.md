## QA Checklist
![""](https://external-preview.redd.it/Jqajg2t7_BaVoWVA7k5tcckotT7AvuCWSi5X94KTwJ8.jpg?auto=webp&s=6c5a9549b516dde8db9776482d491230716b585a)

###### /orders
- [ ] Create a new work order,
- [ ] Add a note to a work order,
- [ ] Assign a work order
- [ ] Outsource a work order
- [ ] Outsource a multiple work orders
- [ ] Ensure notes are loading on work orders
- [ ] Ensure downloading a list of work orders works.
- [ ] Revoke a work order.
- [ ] Revoke multiple work orders.
- [ ] No relevant errors appear when tailing the logs: `tail -f log/warn.log log/error.log`

###### /saved_forms
- [ ] No relevant errors appear when tailing the logs: `tail -f log/warn.log log/error.log`
- [ ] Can view saved applications
- [ ] Can view progress of saved applications

###### /techs
- [ ] Create a new tech
- [ ] Delete a tech
- [ ] Update a tech (including the skill categories)
- [ ] Update a tech's pass code
- [ ] Techs show up on `/techs`
- [ ] Can browse individual techs
- [ ] No relevant errors appear when tailing the logs: `tail -f log/warn.log log/error.log`

###### /cards
- [ ] Ensure list loads
- [ ] Ensure hidden cards loads
- [ ] Ensure updating any field works
- [ ] Ensure adding a unit works
- [ ] No relevant errors appear when tailing the logs: `tail -f log/warn.log log/error.log`

###### /maintenance_reports
- [ ] Ensure all charts and boxes load on Dashboard
- [ ] Ensure all charts and boxes load on Property Metrics
- [ ] Ensure all charts and boxes load on Unit Breakdown
- [ ] Ensure all charts and boxes load on Synopsis
- [ ] Ensure all charts and boxes load on Tech Performance
- [ ] No relevant errors appear when tailing the logs: `tail -f log/warn.log log/error.log`

###### /approvals:
- [ ] Ensure list loads
- [ ] Create a new approval
- [ ] Bug a person and verify email sent
- [ ] Add a person to a log
- [ ] Ensure approving works
- [ ] Ensure declining works
- [ ] No relevant errors appear when tailing the logs: `tail -f log/warn.log log/error.log`

###### /payments
- [ ] Ensure list loads
- [ ] Ensure filtering and sorting works
- [ ] Ensure exporting list of payments works
- [ ] No relevant errors appear when tailing the logs: `tail -f log/warn.log log/error.log`

###### /payments_analytics
- [ ] Ensure all charts and boxes load
- [ ] No relevant errors appear when tailing the logs: `tail -f log/warn.log log/error.log`

Please only check the box AFTER you have verified that it still works.
