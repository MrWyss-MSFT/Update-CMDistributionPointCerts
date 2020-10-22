#requires -Module ConfigurationManager

#region Variable Declarations 
$CertificateTemplateName = "SCCM DistributionPoint Cert (exportable)"
$CertPath = "Cert:\LocalMachine\My"
$PFXFilePath = "e:\" # Local drive/folder on the DPs, trailing \ required
#endregion

$SecureString = Read-Host -AsSecureString 'Enter password for the PFX File'

#region Export Script that runs on the Distribution Points
$ExportCertScriptBlock = {
    param ($SecureString, $CertificateTemplateName, $CertPath, $PFXFilePath)
    $DPCert = Get-ChildItem $CertPath | Where-Object { $_.Extensions | Where-Object { $_.oid.friendlyname -match "Certificate Template Information" -and $_.Format(0) -like "*$CertificateTemplateName*" } }
    if ($DPCert) {
        Write-Host "Found exportable cert, 📅 expiring: $($DPCert.GetExpirationDateString())" -ForegroundColor Green
        $ExportLocation = ($PFXFilePath + ($DPCert.DnsNameList).Unicode) + ".pfx"
        Write-Host "Exporting to: $ExportLocation" -ForegroundColor Green
        $PFXCert = Export-PfxCertificate -Cert $DPCert -Password $SecureString -FilePath $ExportLocation
        New-Object -TypeName PSCustomObject -Property @{Host = $env:computername; Output = $PFXCert; ExitCode = $exitCode }

    }
    else {
        Write-Host "❌ Certificate not found" -ForegroundColor Red
    }
}
#endregion

#region Main Loop all DPs excluding Cloud DPs
$DPs = Get-CMDistributionPoint | Where-Object NALType -NE "Windows Azure"
$DPCount = 0
$DPSkipCount = 0

Foreach ($DP in $DPs) {
    $DPCount++
    $skip = $false
    $DPName = $DP.NetworkOSPath.Replace("\\", "")
    Write-Progress -Activity 'Processing Distribution Points' -CurrentOperation $DPName -PercentComplete (($DPCount / $DPs.count) * 100)
    Write-Host "$DPName" -ForegroundColor Green
    try {
        $Return = Invoke-Command -ComputerName $DPName -ScriptBlock $ExportCertScriptBlock -ArgumentList $SecureString, $CertificateTemplateName, $CertPath, $PFXFilePath
    }
    catch {
        Write-Host "Could not run cert export scriptblock" -ForegroundColor Red
        Write-Host $PSItem.ToString() -ForegroundColor Red
        Write-Host "skipping $DPName" -ForegroundColor Green
        $skip = $true
        $DPSkipCount++
    }
    
    If ($skip -eq $false) {
        $RemotePFXFilePath = "\\{0}\{1}\{2}" -f $Return.PSComputerName, $Return.Output.Directory.Replace(":\", "$"), $Return.Output.Name
        Write-Host "Remote PFX Path : $RemotePFXFilePath" -ForegroundColor Green
        Set-CMDistributionPoint -SiteSystemServerName $DPName -CertificatePath $RemotePFXFilePath -CertificatePassword $SecureString -Force
        Write-Host "$DPName is done" -ForegroundColor Green
    }

    Write-Host ""
}
#endregion


$SuccessRate = "{0:N0}" -f ((($DPs.count - $DPSkipCount) / $DPs.count) * 100)

Write-Host "$DPSkipCount skipped" -ForegroundColor Green
Write-Host "✔ $SuccessRate done 👍👍👍" -ForegroundColor Green
Write-Host "🚩 PFX files reside on the DPs 🚩 you might want to delete them" -ForegroundColor Blue