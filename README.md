# Update-CMDistributionPointCert

Example scrip; If you need to update your DistributionPoints certificates, if they have expired or if you have restored your MECM environment.

## Script Sequence

1. Asks for an import/export Password
2. loops through all your DP except CloudDPs
3. exports the Certificate with the private key locally to the DP via Remote Powershell using the Password
4. Imports the DP Cert using Set-CMDistributionPoint using the Password

## Prerequisites

* Exportable Server [Server Auth](https://docs.microsoft.com/en-us/mem/configmgr/core/plan-design/network/pki-certificate-requirements#BKMK_PKIcertificates_for_servers:~:text=Enhanced%20Key%20Usage%20value%20must%20contain%20Server%20Authentication%20(1.3.6.1.5.5.7.3.1).,-If) in the My Computer Store
* Account that is is local admin on the DPs
* SMB Access from Host that hosts the console to the DPs
* [Remote Powershell](https://docs.microsoft.com/en-us/powershell/scripting/learn/remoting/running-remote-commands?view=powershell-7 "Remote Powershell") enabled on the DPs and accessible from the Host

## Usage

Open ISE from the MECM Console.

![Open ISE](/assets/images/openise.png)

Copy [Update-CMDistributionPointCerts.ps1](./Update-CMDistributionPointCerts.ps1) below roughly line #35

Change these Variables

```powershell
$CertificateTemplateName = "MECM DistributionPoint Cert (exportable)"
$CertPath = "Cert:\LocalMachine\My"
$PFXFilePath = "e:\" # Local drive/folder on the DPs, trailing \ required
```

Set BreakPoints in the main loop

run the script
