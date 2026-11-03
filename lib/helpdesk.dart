/// Public helpdesk contact — keep in sync with kebuone-website `src/lib/contact.ts`.
const helpdeskEmail = 'helpdesk@kebuone.in';
const helpdeskPhone10 = '8726006519';
const helpdeskPhoneDisplay = '+91 $helpdeskPhone10';
const helpdeskTelUri = 'tel:+91$helpdeskPhone10';

String get helpdeskLine => '$helpdeskEmail · $helpdeskPhoneDisplay';
