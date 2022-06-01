const tooltips = [
  {
    id: 'more_info_application_fee',
    content: 'The amount to charge per Lease Holder on the application.'
  },
  {
    id: 'more_info_admin_fee',
    content: 'The admin fee to charge applicants before they can move in. Standard is $150'
  },
  {
    id: 'more_info_instant_screen',
    content: 'Instant Screen, when on, will screen the applicant at the current Market Rent for the floorplan that the applicant selected. Please make sure that there are floorplans set up and that there is a market rent for each floorplan.'
  },
  {
    id: 'more_info_applicant_info_visible',
    content: 'Whether to display confidential info to Property Managers and Leasing Agents. Should be on when the property is fully using AppRent.'
  },
  {
    id: 'more_info_area_rate',
    content: 'The amount to charge per square foot on top of the market rent.'
  },
  {
    id: 'more_info_notice_period',
    content: 'How many days residents must tell us before the lease end that they are not renewing. Notifying of Intent to Vacate in less days will result in a fee applied.'
  },
  {
    id: 'more_info_renewal_overage_threshold',
    content: 'If a lease package increases the rent more than the percentage listed here, the system will ask for the Admin to create Custom Packages.'
  },
  {
    id: 'more_info_mtm_multiplier',
    content: 'The amount to times the market rent by. Is used to calculate MTM amounts.'
  },
  {
    id: 'more_info_mtm_fee',
    content: 'The fee that gets added on top of the Market Rent for MTM residents'
  },
  {
    id: 'more_info_late_fee_threshold',
    content: 'Anyone with a balance greater than this amount will automatically get late fees added.'
  },
  {
    id: 'more_info_grace_period',
    content: 'The number of days in which residents have to pay their balance before they get charged late fees.'
  },
  {
    id: 'more_info_late_fee',
    content: 'The amount of the fee that will be added if a late fee needs to be applied. Also whether to charge a percentage of the rent or a flat $ amount.'
  },
  {
    id: 'more_info_daily_late_fee_addition',
    content: 'Whether late fees are added once a month or are applied daily, and for how many days.'
  },
  {
    id: 'more_info_nsf_fee',
    content: 'How much to charge whenever a payment gets NSFd'
  },
  {
    id: 'more_info_accepts_partial_payments',
    content: 'Whether this property will allow AppRent to accept payments that are less than the stated total balance.'
  },
  {
    id: 'more_info_default_bank_account_id',
    content: 'Bank account which will receive all electronic payments.'
  },
  {
    id: 'more_info_active',
    content: 'In-Active property means it will not show up except for Super Admins and only on the properties page. '
  }
];

export default tooltips;