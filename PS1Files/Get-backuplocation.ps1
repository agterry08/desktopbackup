$activity = "Getting Local IP Addresses"
$ID = 1
$totalSteps = 4
$Step = 1
$stepText = "Getting Local IP Addresses and Setting Credential Variables"
$statusText = '"Step $($Step.ToString().PadLeft($TotalSteps.Count.ToString().Length)) of $TotalSteps | $StepText"'
$statusBlock = [ScriptBlock]::Create($statusText)
$Task = "$_"
Write-Progress -Id $ID -Activity $activity -Status (& $StatusBlock) -CurrentOperation $Task -PercentComplete ($Step / $TotalSteps * 100)
$dnsdomain = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=true | Select-Object -ExpandProperty dnsdomain
[System.Net.Dns]::GetHostaddresses($dnsdomain) | % {
($_).IPAddressToString | Add-Content C:\itaotemp\desktopbackupscripts\temp\IPs.txt
}
Get-Content C:\itaotemp\desktopbackupscripts\temp\IPs.txt | Select-object -First 1 | Out-File C:\itaotemp\desktopbackupscripts\TEMP\IP.txt
$IPs = Get-Content C:\itaotemp\desktopbackupscripts\temp\IP.txt
$username = "$env:userdomain\rtsadmin"
$password = Get-Content "C:\itaotemp\desktopbackupscripts\temp\encrypted_password.txt" | ConvertTo-SecureString
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
function Invoke-TSPingSweep { 
  Param( 
    [parameter(Mandatory = $true, 
      Position = 0)] 
    [ValidatePattern("\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b")] 
    [string]$StartAddress, 
    [parameter(Mandatory = $true, 
      Position = 1)] 
    [ValidatePattern("\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b")] 
    [string]$EndAddress, 
    [switch]$ResolveHost, 
    [switch]$ScanPort, 
    [int[]]$Ports = @(21,22,23,53,69,71,80,98,110,139,111,389,443,445,1080,1433,2001,2049,3001,3128,5222,6667,6868,7777,7878,8080,1521,3306,3389,5801,5900,5555,5901), 
    [int]$TimeOut = 100 
  ) 
  Begin { 
    $ping = New-Object System.Net.Networkinformation.Ping 
  } 
  Process { 
    foreach($a in ($StartAddress.Split(".")[0]..$EndAddress.Split(".")[0])) { 
      foreach($b in ($StartAddress.Split(".")[1]..$EndAddress.Split(".")[1])) { 
        foreach($c in ($StartAddress.Split(".")[2]..$EndAddress.Split(".")[2])) { 
          foreach($d in ($StartAddress.Split(".")[3]..$EndAddress.Split(".")[3])) { 
            write-progress -activity PingSweep -status "$a.$b.$c.$d" -percentcomplete (($d/($EndAddress.Split(".")[3])) * 100) 
            $pingStatus = $ping.Send("$a.$b.$c.$d",$TimeOut) 
            if($pingStatus.Status -eq "Success") { 
              if($ResolveHost) { 
                write-progress -activity ResolveHost -status "$a.$b.$c.$d" -percentcomplete (($d/($EndAddress.Split(".")[3])) * 100) -Id 1 
                $getHostEntry = [Net.DNS]::BeginGetHostEntry($pingStatus.Address, $null, $null) 
              } 
              if($ScanPort) { 
                $openPorts = @() 
                for($i = 1; $i -le $ports.Count;$i++) { 
                  $port = $Ports[($i-1)] 
                  write-progress -activity PortScan -status "$a.$b.$c.$d" -percentcomplete (($i/($Ports.Count)) * 100) -Id 2 
                  $client = New-Object System.Net.Sockets.TcpClient 
                  $beginConnect = $client.BeginConnect($pingStatus.Address,$port,$null,$null) 
                  if($client.Connected) { 
                    $openPorts += $port 
                  } else { 
                    # Wait 
                    Start-Sleep -Milli $TimeOut 
                    if($client.Connected) { 
                      $openPorts += $port 
                    } 
                  } 
                  $client.Close() 
                } 
              } 
              if($ResolveHost) { 
                $hostName = ([Net.DNS]::EndGetHostEntry([IAsyncResult]$getHostEntry)).HostName 
              } 
              # Return Object 
              New-Object PSObject -Property @{ 
                IPAddress = "$a.$b.$c.$d"; 
                HostName = $hostName; 
                Ports = $openPorts 
              } | Select-Object IPAddress, HostName, Ports 
            } 
          } 
        } 
      } 
    } 
  } 
  End { 
  } 
}
function Validate-IP ($strIP){
	$bValidIP = $true
	$arrSections = @()
	$arrSections +=$strIP.split(".")
	#firstly, make sure there are 4 sections in the IP address
	if ($arrSections.count -ne 4) {$bValidIP =$false}
	
	#secondly, make sure it only contains numbers and it's between 0-254
	if ($bValidIP)
	{
		[reflection.assembly]::LoadWithPartialName("'Microsoft.VisualBasic") | Out-Null
		foreach ($item in $arrSections)
		{
			if (!([Microsoft.VisualBasic.Information]::isnumeric($item))) {$bValidIP = $false}
		}
	}
	
	if ($bValidIP)
	{
		foreach ($item in $arrSections)
		{
			$item = [int]$item
			if ($item -lt 0 -or $item -gt 254) {$bValidIP = $false}
		}
	}
	
	Return $bValidIP
}
function Validate-SubnetMask ($strSubnetMask){
	$bValidMask = $true
	$arrSections = @()
	$arrSections +=$strSubnetMask.split(".")
	#firstly, make sure there are 4 sections in the subnet mask
	if ($arrSections.count -ne 4) {$bValidMask =$false}
	
	#secondly, make sure it only contains numbers and it's between 0-255
	if ($bValidMask)
	{
		[reflection.assembly]::LoadWithPartialName("'Microsoft.VisualBasic") | Out-Null
		foreach ($item in $arrSections)
		{
			if (!([Microsoft.VisualBasic.Information]::isnumeric($item))) {$bValidMask = $false}
		}
	}
	
	if ($bValidMask)
	{
		foreach ($item in $arrSections)
		{
			$item = [int]$item
			if ($item -lt 0 -or $item -gt 255) {$bValidMask = $false}
		}
	}
	
	#lastly, make sure it is actually a subnet mask when converted into binary format
	if ($bValidMask)
	{
		foreach ($item in $arrSections)
		{
			$binary = [Convert]::ToString($item,2)
			if ($binary.length -lt 8)
			{
				do {
				$binary = "0$binary"
				} while ($binary.length -lt 8)
			}
			$strFullBinary = $strFullBinary+$binary
		}
		if ($strFullBinary.contains("01")) {$bValidMask = $false}
		if ($bValidMask)
		{
			$strFullBinary = $strFullBinary.replace("10", "1.0")
			if ((($strFullBinary.split(".")).count -ne 2)) {$bValidMask = $false}
		}
	}
	Return $bValidMask
}
function ConvertTo-Binary ($strDecimal){
	$strBinary = [Convert]::ToString($strDecimal, 2)
	if ($strBinary.length -lt 8)
	{
		while ($strBinary.length -lt 8)
		{
			$strBinary = "0"+$strBinary
		}
	}
	Return $strBinary
}
function Convert-IP-To-Binary ($strIP){
	$strBinaryIP = $null
	if (Validate-IP $strIP)
	{
		$arrSections = @()
		$arrSections += $strIP.split(".")
		foreach ($section in $arrSections)
		{
			if ($strBinaryIP -ne $null)
			{
				$strBinaryIP = $strBinaryIP+"."
			}
				$strBinaryIP = $strBinaryIP+(ConvertTo-Binary $section)
			
		}
	}
	Return $strBinaryIP
}
Function Convert-SubnetMask-To-Binary ($strSubnetMask){
		$strBinarySubnetMask = $null
	if (Validate-SubnetMask $strSubnetMask)
	{
		$arrSections = @()
		$arrSections += $strSubnetMask.split(".")
		foreach ($section in $arrSections)
		{
			if ($strBinarySubnetMask -ne $null)
			{
				$strBinarySubnetMask = $strBinarySubnetMask+"."
			}
				$strBinarySubnetMask = $strBinarySubnetMask+(ConvertTo-Binary $section)
			
		}
	}
	Return $strBinarySubnetMask
}
Function Convert-BinaryIPAddress ($BinaryIP){
	$FirstSection = [Convert]::ToInt64(($BinaryIP.substring(0, 8)),2)
	$SecondSection = [Convert]::ToInt64(($BinaryIP.substring(8,8)),2)
	$ThirdSection = [Convert]::ToInt64(($BinaryIP.substring(16,8)),2)
	$FourthSection = [Convert]::ToInt64(($BinaryIP.substring(24,8)),2)
	$strIP = "$FirstSection`.$SecondSection`.$ThirdSection`.$FourthSection"
	Return $strIP
}
ForEach ($IP in $IPs) {
    $SubnetMask = "255.255.255.0"
	$BinarySubnetMask = (Convert-SubnetMask-To-Binary $SubnetMask).replace(".", "")
	$BinaryNetworkAddressSection = $BinarySubnetMask.replace("1", "")
	$BinaryNetworkAddressLength = $BinaryNetworkAddressSection.length
	$CIDR = 32 - $BinaryNetworkAddressLength
	$iAddressWidth = [System.Math]::Pow(2, $BinaryNetworkLength)
	$iAddressPool = $iAddressWidth -2
	$BinaryIP = (Convert-IP-To-Binary $IP).Replace(".", "")
	$BinaryIPNetworkSection = $BinaryIP.substring(0, $CIDR)
	$BinaryIPAddressSection = $BinaryIP.substring($CIDR, $BinaryNetworkAddressLength)
	$FirstAddress = $BinaryNetworkAddressSection -replace "0$", "1"
	$BinaryFirstAddress = $BinaryIPNetworkSection + $FirstAddress
	$strFirstIP = Convert-BinaryIPAddress $BinaryFirstAddress
	$LastAddress = ($BinaryNetworkAddressSection -replace "0", "1") -replace "1$", "0"
	$BinaryLastAddress = $BinaryIPNetworkSection + $LastAddress
	$strLastIP = Convert-BinaryIPAddress $BinaryLastAddress
    Invoke-TSPingSweep -StartAddress $strFirstIP -EndAddress $strLastIP -ResolveHost | Select-Object -ExpandProperty HostName | Out-file C:\itaotemp\desktopbackupscripts\temp\hostnamesunorganized.txt
}

Start-Sleep -s 30

$duplicates = "C:\itaotemp\desktopbackupscripts\temp\hostnamesunorganized.txt"

Get-Content $duplicates | Sort | Get-Unique > C:\itaotemp\desktopbackupscripts\temp\hostnames.txt
New-Item -path C:\itaotemp\desktopbackupscripts\TEMP\servers.txt -ItemType "file" -Force
$hostnamesfile = "C:\itaotemp\desktopbackupscripts\temp\hostnames.txt"
Get-Content $hostnamesfile | ForEach-Object { 
$username = "$env:userdomain\rtsadmin"
$password = Get-Content "C:\itaotemp\desktopbackupscripts\temp\encrypted_password.txt" | ConvertTo-SecureString
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
Get-WmiObject -Class win32_operatingsystem -ComputerName $_ -Credential $cred |  Where-Object -property Name -like 'Microsoft Windows Serv*' | Select-Object -ExpandProperty PSComputername | Add-Content C:\itaotemp\desktopbackupscripts\temp\servers.txt
}
Start-Sleep -s 30
$servers = "C:\itaotemp\desktopbackupscripts\temp\servers.txt"
Get-Content $servers |ForEach-Object{
$username = "$env:userdomain\rtsadmin"
$password = Get-Content "C:\itaotemp\desktopbackupscripts\temp\encrypted_password.txt" | ConvertTo-SecureString
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
$share = Get-WmiObject -Class win32_share -ComputerName $_ -Credential $cred | Where-Object -Property Name -EQ desktop$ | Select-Object -ExpandProperty Name
$computername = Get-WmiObject -Class win32_share -ComputerName $_ -Credential $cred | Where-Object -Property Name -EQ desktop$ | Select-Object -ExpandProperty PSComputerName


add-Content -Path C:\itaotemp\desktopbackupscripts\temp\desktopbackup.txt -Value "\\$computername\$share"
Start-Sleep -Seconds 5
}


$match1 = "\\\"
Get-Content "C:\itaotemp\desktopbackupscripts\temp\desktopbackup.txt" | % {if ($_ -notlike $match1){$_} }| Select-Object -First 1| Set-Content C:\itaotemp\desktopbackupscripts\desktopbackuplocation.txt
