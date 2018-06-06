O365-GlobalAdminMfaDisabledReport
===========
Searches for global admins with multifactor authentication disabled in a Office 365 tenant.
    
Option to send a CSV report over e-mail.
    
Designed for execution in Azure Automation.

This script was developed as part of a blog [article] on [soren.cloud].

*Note: This script is designed for execution in an Azure Automation runbook!*

## Requirements 
* Azure Subscription
* Office 365 tenant

## Prerequisites
See [prerequisites] section in this [article].

## Usage
Copy the content of the script into a Azure Automation PowerShell Runbook. Then test and deploy (schedule) :-)

**Disclaimer: No warranties. Use at your own risk.**

## Parameters
* **-AutomationPSCredentialName**, Name of the Automation Credential used when connecting to Office 365 / Azure Active Directory.
* **-ExcludeUserAccount**, Global admins to be excluded when searching for accounts with MFA disabled.
* **-SendReport**, If this switch is present, the script sends an email with a CSV file attached, if any MFA-disabled accounts are detected.
* **-ReportSmtpServerAddress**, This field is mandatory if 'SendReport' switch is present. Defines the SMTP server address (FQDN or IP address).
* **-ReportSmtpServerPort**, This field is mandatory if 'SendReport' switch is present. Defines the port used by the SMTP server.
* **-ReportSmtpToAddress**, This field is mandatory if 'SendReport' switch is present. Defines the recipient address(es) when sending reports.
* **-ReportSmtpPSCredentialName**, This field is mandatory if 'SendReport' switch is present. Name of the Automation Credential used when connecting sending a report.
* **-EnableVerbose**, If this switch is present, 'VerbosePreference' will be set to "Continue" in the script.


## Examples
*Remember: This script is designed for execution in a Azure Automation runbook!*

`AutomationPSCredentialName: Office 365 - User Management Service Account`, `ExcludeUserAccount: ['gadmin1@tenant.onmicrosoft.com']`, `SendReport: false`, `EnableVerbose: false`

Connect with service account 'Office 365 - User Management Service Account, Exclude global admin''gadmin1@tenant.onmicrosoft.com'. Do not send a report if any Global Admins with MFA is disabled.

`AutomationPSCredentialName: Office 365 - User Management Service Account`, `ExcludeUserAccount: ['gadmin1@tenant.onmicrosoft.com']`, `SendReport: true`, `ReportSmtpServerAddress: smtp.office365.com`, `ReportSmtpServerPort: 587`, `ReportSmtpFromAddress: Office 365 Automation <noreply@domain.com>`, `ReportSmtpToAddress: ["recipient_a@domain.com","recipient_b@domain.com"]`, `ReportSmtpPSCredentialName: Office 365 Automation Mailbox`,`EnableVerbose: false`

Connect with service account 'Office 365 - User Management Service Account, Exclude global admin''gadmin1@tenant.onmicrosoft.com'. Send a report if any Global Admins with MFA is disabled and output is verbose.

## More Information
[Article]


## Credits
Written by: Søren Lindevang

Find me on:

* My Blog: <http://soren.cloud>
* Twitter: <https://twitter.com/SorenLindevang>
* LinkedIn: <https://www.linkedin.com/in/lindevang/>
* GitHub: <https://github.com/soren-cloud>

[article]: http://soren.cloud/o365-secure-score-azure-automation-part-3-global-admin-with-mfa-disabled-report
[my blog]: http://soren.cloud/
[soren.cloud]: http://soren.cloud/
[prerequisites]: http://soren.cloud/o365-secure-score-azure-automation-part-3-global-admin-with-mfa-disabled-report/#Prerequisites