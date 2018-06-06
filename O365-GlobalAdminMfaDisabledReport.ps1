<#PSScriptInfo
.VERSION 1.0
.GUID 90295b93-0521-4a62-bd5f-e73637ee59a5
.AUTHOR Soren Lindevang
.COMPANYNAME
.COPYRIGHT
.TAGS PowerShell Office 365 Reporting Report Multifactor MultifactorAuthentication Authentication MFA Azure Automation
.LICENSEURI
.PROJECTURI
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
#>

<#
.SYNOPSIS 
    Generate Report of Office 365 Global Admins not secured with multi-factor authentication.

.DESCRIPTION
    Searches for global admins with multifactor authentication disabled in a Office 365 tenant.
    
    Option to send a CSV report over e-mail.
    
    Designed for execution in Azure Automation.

    Check out the GitHub Repo for more information: http://soren.cloud/o365-secure-score-azure-automation-part-3-global-admin-with-mfa-disabled-report

.PARAMETER AutomationPSCredentialName
    Name of the Automation Credential used when connecting to Office 365 / Azure Active Directory.

    The Account should at least have 'User management administrator' rights in the tenant.

    Example: Office 365 - User Management Service Account

.PARAMETER ExcludeUserAccount
    Global admins to be excluded when searching for accounts with MFA disabled.

    Must be the user principal name (UPN) of the global admin account(s).

    Example 1: ['gadmin1@tenant.onmicrosoft.com']
    Example 2: ['gadminA@tenant.onmicrosoft.com','gadminB@tenant.onmicrosoft.com']

.PARAMETER SendReport 
     If this switch is present, the script sends an email with a CSV file attached, if any MFA-disabled accounts are detected.
     
     If used, please do modify the 'SendMailReport' variables in the 'Declarations' area.

     Example 1: true
     Example 2: false

     Default value = false

.PARAMETER ReportSmtpServerAddress
     This field is mandatory if 'SendReport' switch is present. Defines the SMTP server address (FQDN or IP address)

     Example 1: smtp.office365.com
     Example 2: 123.45.67

.PARAMETER ReportSmtpServerPort
     This field is mandatory if 'SendReport' switch is present. Defines the port used by the SMTP server
     
     Example 1: 587
     Example 2: 25       


.PARAMETER ReportSmtpFromAddress
     This field is mandatory if 'SendReport' switch is present. Defines the from address when sending reports

     Example 1: Office 365 Automation <noreply@domain.com>
     Example 2: noreply@domain.com 

.PARAMETER ReportSmtpToAddress
     This field is mandatory if 'SendReport' switch is present. Defines the recipient address(es) when sending reports

     Example 1: ["recipient_a@domain.com"]
     Example 2: ["recipient_a@domain.com","recipient_b@domain.com"]

.PARAMETER ReportSmtpPSCredentialName
    This field is mandatory if 'SendReport' switch is present. Name of the Automation Credential used when connecting sending a report.

    If using a Exchange Online Mailbox, the Account should at least have 'send-as' permissions of the mailbox defined in 'ReportSmtpFromAddress'.

    Example: Office 365 Automation Mailbox

.PARAMETER EnableVerbose 
     If this switch is present, 'VerbosePreference' will be set to "Continue" in the script.
     
     Build-in Verbose switch is not supported by Azure Automation (yet).
     
     Example 1: true
     Example 2: false

     Default value = false

.INPUTS
    N/A

.OUTPUTS
    N/A

.NOTES
    Version:        1.0
    Author:         Soren Greenfort Lindevang
    Creation Date:  06.06.2018
    Purpose/Change: Initial script development
  
.EXAMPLE
    N/A
#>
[cmdletbinding()]
param (
    [Parameter(
        Mandatory=$true)]
        [string]$AutomationPSCredentialName,
    [Parameter(
        Mandatory=$false)]
        [string[]]$ExcludeUserAccount,
    [Parameter(
        Mandatory=$false)]
        [switch]$SendReport,
    [Parameter(
        Mandatory=$false)]
        [string]$ReportSmtpServerAddress,
    [Parameter(
        Mandatory=$false)]
        [string]$ReportSmtpServerPort,
    [Parameter(
        Mandatory=$false)]
        [string]$ReportSmtpFromAddress,
    [Parameter(
        Mandatory=$false)]
        [string[]]$ReportSmtpToAddress,
    [Parameter(
        Mandatory=$false)]
        [string]$ReportSmtpPSCredentialName,
    [Parameter(
        Mandatory=$false)]
        [switch]$EnableVerbose
)


#-----------------------------------------------------------[Functions]------------------------------------------------------------

# Test if script is running in Azure Automation
function Test-AzureAutomationEnvironment
    {
    if ($env:AUTOMATION_ASSET_ACCOUNTID)
        {
        Write-Verbose "This script is executed in Azure Automation"
        }
    else
        {
        $ErrorMessage = "This script is NOT executed in Azure Automation."
        throw $ErrorMessage
        }
    }

function Stop-AutomationScript
    {
    param(
        [ValidateSet("Failed","Success")]
        [string]
        $Status = "Success"
        )
    Write-Output ""
    if ($Status -eq "Success")
        {
        Write-Output "Script successfully completed"
        }
    elseif ($Status -eq "Failed")
        {
        Write-Output "Script stopped with an Error"
        }
    Break
    }


#----------------------------------------------------------[Declarations]----------------------------------------------------------

# General Send Report Variables
$ReportSubject = "Report: Global Admin(s) with MFA Disabled"
$ReportBody = "CSV file attached, containing Global Admins with MFA disabled" 



#-----------------------------------------------------------[Execution]-----------------------------------------------------------

# Check if script is executed in Azure Automation
Test-AzureAutomationEnvironment

Write-Output "::: Parameters :::"
Write-Output "AutomationPSCredentialName: $AutomationPSCredentialName"
Write-Output "ExcludeUserAccount:         $ExcludeUserAccount"
Write-Output "SendReport:                 $SendReport"
Write-Output "ReportSmtpServerAddress     $ReportSmtpServerAddress"
Write-Output "ReportSmtpServerPort        $ReportSmtpServerPort"
Write-Output "ReportSmtpFromAddress       $ReportSmtpFromAddress"
Write-Output "ReportSmtpToAddress         $ReportSmtpToAddress"
Write-Output "ReportSmtpPSCredentialName: $ReportSmtpPSCredentialName"
Write-Output "EnableVerbose:              $EnableVerbose"
Write-Output ""

# Handle Verbose Preference
if ($EnableVerbose -eq $true)
    {
    $VerbosePreference = "Continue"
    }

# Get AutomationPSCredential
Write-Output "::: Connection :::"
try
    {
    Write-Output "Importing Automation Credential"
    $Credential = Get-AutomationPSCredential -Name $AutomationPSCredentialName -ErrorAction Stop
    }
catch 
    {
    Write-Error $_.Exception
    Stop-AutomationScript -Status Failed
    }
Write-Verbose "Successfully imported credentials"

# Connect MsolService
try 
    {
    Connect-MsolService -Credential $Credential -ErrorAction Stop
    }
catch
    {
    Write-Error $_.Exception
    Stop-AutomationScript -Status Failed
    }

# Collect Global Admins with MFA Disabled
try
    {
    $GlobalAdminRole = Get-MsolRole -RoleName "Company Administrator" -ErrorAction Stop
    $GlobalAdminMembers = Get-MsolRoleMember -RoleObjectId $GlobalAdminRole.ObjectId -ErrorAction Stop
    $GlobalAdminMembersCount = $($GlobalAdminMembers | Measure-Object).Count
    $GlobalAdminsMfaDisabled = $GlobalAdminMembers | Where-Object {!$_.StrongAuthenticationRequirements}
    $GlobalAdminsMfaDisabledCount = $($GlobalAdminsMfaDisabled | Measure-Object).Count
    }
catch 
    {
    Write-Error $_.Exception
    Stop-AutomationScript -Status Failed
    }

if ($GlobalAdminsMfaDisabled)
    {
    Write-Verbose "Successfully Collected Global Admins with MFA Disabled"
    Write-Output "Found $GlobalAdminsMfaDisabledCount Global Admin(s) with MFA Disabled"
    $count = $null
    foreach ($GlobalAdmin in $GlobalAdminsMfaDisabled)
        {
        $count++
        Write-Verbose "($count): $($GlobalAdmin.EmailAddress)"
        }
    }
else
    {
    Write-Output "All Global Admins ($GlobalAdminMembersCount) have MFA enabled"
    Stop-AutomationScript -Status Success
    }


# Exclusion
if ($ExcludeUserAccount)
    {
    Write-Verbose "User Account Exclusion Switch Set - Processesing"
    $GlobalAdminsMfaDisabled_Excluded = $GlobalAdminsMfaDisabled | Where-Object {$ExcludeUserAccount -contains $_.EmailAddress}
    $GlobalAdminsMfaDisabled_ToProcess = $GlobalAdminsMfaDisabled | Where-Object {$ExcludeUserAccount -notcontains $_.EmailAddress}
    foreach ($GlobalAdmin in $GlobalAdminsMfaDisabled_Excluded)
        {
        Write-Output "Excluded following Global Admin: $($GlobalAdmin.EmailAddress)"
        }
    if (!$GlobalAdminsMfaDisabled_ToProcess)
        {
        Write-Output "All Global Admins with MFA Disabled has been Excluded"
        Stop-AutomationScript -Status Success
        }
    elseif (!$GlobalAdminsMfaDisabled_Excluded)
        {
        Write-Output "No Global Admins with MFA Disabled Matched the Exclusion List"
        }
    }
else
    {
    Write-Verbose "No User Account Exclusion Switch Set - Continuing"
    }
    

# Send Mail Report
if ($SendReport)
    {
    Write-Output ""
    Write-Output "::: Send Mail Report :::"
    Write-Output "Importing Automation Credential"
    try
        {
        $ReportSmtpPSCredential = Get-AutomationPSCredential -Name $ReportSmtpPSCredentialName -ErrorAction Stop
        }
    catch 
        {
        Write-Error $_.Exception
        Stop-AutomationScript -Status Failed
        }
    Write-Verbose "Successfully imported credentials"

    $ReportTime = Get-Date -Format "MM-dd-yyyy_HH-mm-ss"

    Write-Output "Generate MFA Disabled CSV file"
    try
        {
        $CSVFileName = "GlobalAdminMfaDisabled_" + $ReportTime + ".csv"
        $CSVFilePath = $env:TEMP + "\" + $CSVFileName
        $GlobalAdminsMfaDisabled_ToProcess | Select-Object EmailAddress,DisplayName `
            | Export-CSV -LiteralPath $CSVFilePath -Encoding Unicode -NoTypeInformation -Delimiter "`t" -ErrorAction Stop
        }
    catch 
        {
        Write-Error $_.Exception
        Stop-AutomationScript -Status Failed
        }
    Write-Verbose "Successfully Generated MFA Disabled CSV file"
    $ReportSmtpToString = $ReportSmtpToAddress -join ", "
    Write-Output "Send e-mail to '$ReportSmtpToString' from '$ReportSmtpFromAddress'" 
    try
        {
        Send-MailMessage -To $ReportSmtpToAddress -From $ReportSmtpFromAddress -Subject $ReportSubject `
            -Body $ReportBody -BodyAsHtml -Attachments $CSVFilePath -SmtpServer $ReportSmtpServerAddress `
            -Port $ReportSmtpServerPort -UseSsl -Credential $ReportSmtpPSCredential -ErrorAction Stop
        }
    catch 
        {
        Write-Error $_.Exception
        Stop-AutomationScript -Status Failed
        }
    Write-Verbose "Successfully sent e-mail to '$ReportSmtpToString' from '$ReportSmtpFromAddress'"
    }
else
    {
    Write-Output "Report switch set to false. No report is sent."
    Stop-AutomationScript -Status Success
    }

# Script Completed
Stop-AutomationScript -Status Success