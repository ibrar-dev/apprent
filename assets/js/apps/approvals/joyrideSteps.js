import React from 'react';
const steps = [
  {
    target: 'body',
    placement: 'center',
    content: 'Lets begin a walk-through of AppRents new Approval System.',
    locale: {
      next: <span>Begin</span>
    }
  },
  {
    target: '.jr-step-1',
    content: 'First select a vendor. If you are responsible for multiple properties, please make sure you have the correct property set up.'
  },
  {
    target: '.jr-step-2',
    content: 'Make sure you enter a description that accurately describes what is needed in this approval request'
  },
  {
    target: '.jr-step-3',
    content: 'Select a category that best fits the cost for this approval. Note that you can select as many categories and amounts as you deem necessary.'
  },
  {
    target: '.jr-step-4',
    content: 'After you select a category two numbers will appear below the category. The first one is how much you have spent for this category so far. The second is how much the new total will be with this approval request. If the amount shown for the MTD is above 0, you are able to click on the number to see a detailed breakdown.'
  },
  {
    target: '.jr-step-5',
    content: 'Please use the company policy to select the necessary approvers. Note that if you do not select any approvers, than only your immediate superior will be alerted and able to approve the request.'
  },
  {
    target: '.jr-step-6',
    content: 'You can drag any files from your computer into this box to add an attachment. Also, you can click on the box and it will open up a new window allowing you to select the files from your computer.'
  },
  {
    target: '.jr-step-7',
    content: 'Any attachments you add will show up here. You cannot preview them yet in this box, but hopefully that will be coming soon.'
  },
  {
    target: '.jr-step-8',
    content: 'Lastly, after form is filled out, press the Save button to submit the request for approval.',
    locale: {
      last: <span>Finish</span>
    }
  }
]

export default steps;