function Get-Token{
function hash($algorithm, $text) {
$data = [system.Text.Encoding]::UTF8.GetBytes($text)
[string]$hash = -join ([Security.Cryptography.HashAlgorithm]::Create($algorithm).ComputeHash($data) | ForEach { "{0:x2}" -f $_ })
return $hash
}

$vsa = 'https://itassistonline.com/api/v1.0/auth'
$user = 'rts_api_user'
$password = '44?WBs6_z4nyHEk&HZ+r3m4z'
$rand = Get-Random #
$SHA1Hash   = hash "SHA1"   "$password$user"
$SHA256Hash = hash "SHA256" "$password$user"
$SHA1Hash   = hash "SHA1"   "$SHA1Hash$rand"
$SHA256Hash = hash "SHA256" "$SHA256Hash$rand"
$auth = "user=$user,pass2=$SHA256Hash,pass1=$SHA1Hash,rand2=$rand,rpass2=$SHA256Hash,rpass1=$SHA1Hash,twofapass=:undefined"
$encodedauth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($auth))
$request = Invoke-RestMethod -Method Get -Uri $vsa -Headers @{'Authorization' = "Basic $encodedauth"}
$global:token = $request.result.token

}
Get-Token
Function Get-GUID {
$contenttype = "application/json"
$guiduri = "https://itassistonline.com/api/v1.0/assetmgmt/agents?`$filter=ComputerName eq `'$env:computername`' "
$agentinformation = Invoke-RestMethod -Method GET -Uri $guiduri -ContentType $contenttype -Headers @{'Authorization' = "Bearer $global:token"}
$global:GUID = $agentinformation.Result | Select-object -ExpandProperty AgentID
}
Get-GUID
$starton = Get-Date -format yyyy-MM-ddTHH:mm:00.000Z
$contenttype = "application/json"




$agentprocidfull = '1577066399'
$bodyfull = '
{
  "ServerTimeZone": true,
  "SkipIfOffLine": true,
  "PowerUpIfOffLine": false,
  "ScriptPrompts": [
    {
    }
  ],
  "Recurrence": {
    "Repeat": "Weeks",
    "Times": 1,
    "DaysOfWeek": "Wednesday"
  },
  "Distribution": {
    "Interval": "Hours",
    "Magnitude": 1
  },
  "Start": {
    "StartOn": "2018-03-31T16:00:00.000Z",
    "StartAt": "T0000"
  },
  "Attributes": {}
}'
$urifull = "https://itassistonline.com/api/v1.0/automation/agentprocs/$GUID/$agentprocidfull/schedule"
Invoke-RestMethod -Method PUT -Uri $urifull -ContentType $contenttype -Headers @{'Authorization' = "Bearer $global:token"} -Body $bodyfull


$agentprociddiff0900 = '1081998726'
$bodydiff0900 = '
{
  "ServerTimeZone": true,
  "SkipIfOffLine": true,
  "PowerUpIfOffLine": false,
    "ScriptPrompts": [
    {
    }
  ],
  "Recurrence": {
    "Repeat": "Hours",
    "Times": 3
    },
  "Distribution": {
    "Interval": "Minutes",
    "Magnitude": 35
  },
  "Start": {
    "StartOn": "2018-04-02T15:00:00.000Z",
    "StartAt": "T0000"
  },
    "Exclusion": {
    "From": "T1700",
    "To": "T0700"
  },
  "Attributes": {}
}'
$uridiff0900 = "https://itassistonline.com/api/v1.0/automation/agentprocs/$GUID/$agentprociddiff0900/schedule"
Invoke-RestMethod -Method PUT -Uri $uridiff0900 -ContentType application/json -Headers @{'Authorization' = "Bearer $global:token"} -Body $bodydiff0900


<#$agentprocid = '2137305659'
$body = '
{
  "ServerTimeZone": true,
  "SkipIfOffLine": true,
  "PowerUpIfOffLine": false,
  "ScriptPrompts": {},
  "Recurrence": {
    "Repeat": "Weekly",
    "Times": 1,
    "DaysOfWeek": "Wednesday",
    "DayOfMonth": "FirstSunday",
    "SpecificDayOfMonth": 0,
    "MonthOfYear": "January",
    "EndAt": "T0000",
    "EndOn": "2016-02-05T21:02:56.650Z",
    "EndAfterIntervalTimes": 0
  },
  "Distribution": {
    "Interval": "Minutes",
    "Magnitude": 0
  },
  "Start": {
    "StartOn": "2016-02-05T21:02:56.650Z",
    "StartAt": "T0000"
  },
  "Exclusion": {
    "From": "T0000",
    "To": "T0000"
  },
  "Attributes": {}
}'
Invoke-RestMethod -Method PUT -Uri $procscheduleuri -ContentType $contenttype -Headers @{'Authorization' = "Bearer $global:token"} -Body $body
#>