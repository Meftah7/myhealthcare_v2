# MyHealth Privacy Policy

DRAFT FOR OWNER REVIEW. This text describes how this version of the MyHealth app handles information. It has not been approved or published by the operator and is not legal advice. Items marked [to be supplied] must be completed by the operator.

## Who is responsible

MyHealth is operated by [operator legal name — to be supplied]. Contact for privacy questions: [contact channel — to be supplied].

## What the app handles

- Account details: your name, email address, optional national ID used for sign-in, phone number, emergency contact, and a protected (hashed) password.
- Health information: visits, results, medications, allergies, vital signs, imaging, health details and documents issued by your care team or uploaded by you.
- Appointments, home-visit requests, messages with your clinicians, notifications and feedback you send.
- Family and linked accounts: the people you add and the access you grant them.
- Billing records and saved payment-method display details. Payments in this version are simulated and do not move real money. Payment forms accept card number, holder, expiry and security-code inputs for local simulated processing; full card numbers and security codes are not persisted. Saved methods retain display metadata and local token identifiers. No real card processor is connected.
- Preferences such as language, theme and text size.

## Where it is stored

- In the native full app, your information is stored on your device in an encrypted database. The encryption key is kept in your device's secure storage. Device preferences are stored separately; database encryption does not encrypt exported PDFs or every device preference.
- The web version stores information in your browser's storage, which is not encrypted by the app.
- The separate shared-server pilot stores account and clinical information in a server SQLite database. Its document files and backups are encrypted; the application does not itself encrypt the server SQLite database. Hosting location, disk encryption, access controls and production transport security must be confirmed by the operator. Server sessions end after 24 minutes of inactivity or a maximum 12-hour lifetime.

Original PDFs can be downloaded or shared through document actions. Copies saved outside MyHealth are handled by your device or the destination you choose. The operator must confirm backup/export retention and the deployment's document-verification service before publication.

## AI report explanations

When the MyHealth report AI service is connected, the extracted text of the report you choose, your question and recent report-chat turns are sent to that service. The full local app sends extracted text rather than the PDF file to the report AI gateway. The separate shared pilot stores the original on its server and checks authorization before extracting text for AI. The AI service currently implements a Google Gemini provider adapter; the operator must confirm the actual provider, contract, processing country and retention terms before enabling it. The provider receives at most the first 12,000 report characters and bounded recent conversation context. Coverage limits are shown when only part of a report is explained. The AI provider key is held only on the server, never on your device. Answers are drafts, not a diagnosis.

The report gateway handles requests in memory, does not intentionally log request bodies, report text, questions or credentials, and returns no-store responses. This does not establish the third-party provider's retention practices or the hosting proxy's logging settings; these remain [to be supplied]. Report-chat context is cleared on report/account changes or logout. Existing original records remain separate from explanations.

When the service is not connected, summaries are made on your device and nothing is sent.

## Device features

- Camera: used to scan a document-verification QR code and, on supported mobile platforms, take a profile photo when you choose that action.
- Photos and files: only the picture or PDF you choose.
- Notifications: local device delivery depends on permission and your account preferences. Remote delivery services are used only when configured; the operator must identify any enabled email, SMS or push providers and their data handling.

## Sharing

Your care team sees the information needed to look after you, and the people you link to your account see what you allow. Issued certificates can be checked through a verification page that shows minimal details. This version contains no advertising and no third-party analytics.

## Keeping and deleting information

[Retention periods — to be supplied.]

## Your choices and rights

You can review and update your personal details and preferences in the app, and remove family links you created. [How to request access, correction or deletion, and your rights under applicable law — to be supplied.]

## Changes

[How changes to this policy will be announced — to be supplied.]
