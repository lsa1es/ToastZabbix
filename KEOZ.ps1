# Keep Your Eyes on Zabbix 

param(
    [string]$URL,
    [string]$USR,
    [string]$PWS
)

While($true) {
$INICIO=[datetime]”01/01/1970 00:00”
$AGORA=(GET-DATE)
$Future=(GET-DATE).AddMinutes(5)

$ss=((NEW-TIMESPAN –Start $INICIO –End $AGORA).TotalSeconds) -replace ',','.'
$es=((NEW-TIMESPAN –Start $INICIO –End $Future).TotalSeconds) -replace ',','.'

$stime,$smin = $ss.split(".")
$etime,$emin = $es.split(".")

$baseurl = "$URL"
$params = @{
    body =  @{
        "jsonrpc"= "2.0"
        "method"= "user.login"
        "params"= @{
            "user" = $USR
            "password" = $PWS
        }
        "id"= 1
        "auth"= $null
    } | ConvertTo-Json
    uri = "$baseurl/api_jsonrpc.php"
    headers = @{"Content-Type" = "application/json"}
    method = "Post"
}

$result = Invoke-WebRequest @params

$params.body = @{
    "jsonrpc"= "2.0"
    "method"= "trigger.get"
    "params"= @{
        "expandDescription" = 1 
        "maintenance" = 0 
        "min_severity" = 1 
        "monitored" = 1 
        "output" = "extend"
        "lastChangeSince" = $stime
        "lastChangeTill" = $etime
        "skipDependent" = 1 
        "selectHosts" = "extend" 
        "sortorder"= "DESC" 
        "sortfield"= "lastchange"
        "limit" = 1
        "filter" = @{ "value" = 1 }
     }
    auth = ($result.Content | ConvertFrom-Json).result
    id = 2
} | ConvertTo-Json 

$result = Invoke-WebRequest @params 
#write-host $result.Content - $etime - $stime

$desctmp = ($result.Content | ConvertFrom-Json).result | findstr "description" | Select-Object -First 1

if (!$desctmp) {
    write-host "vazio" }
    else {

$tipo,$desc = $desctmp.split(":")

$Hst = ($result.Content | ConvertFrom-Json).result | findstr "hosts"
$Hosts,$Proxy,$AHost,$status = $Hst.split(";")
$ArHost,$NHost =  $AHost.split("=")

$priotmp = ($result.Content | ConvertFrom-Json).result | findstr "priority" | Select-Object -First 1
$tipo,$prios = $priotmp.split(":")
$prio = $prios -replace '\s+','' 


# info - information 1
# warning - average(3) - warning(2)
# error - disaster(5) - high(4) 
if (( $prio -eq "4" ) -or ( $prio -eq "5" ))
        { $Erra = "Error" }
if (( $prio -eq "3" ) -or ( $prio -eq "2" ))
        { $Erra = "Warning" }
if ( $prio -eq "1" )
        { $Erra = "Info" }

#write-host $desc - $Erra - $NHost


[void] [System.Reflection.Assembly]::LoadWithPartialName(“System.Windows.Forms”)
# Remove and Unregister events if created earlier. Tip, remove the events you haven’t created earlier
#Remove-Event BalloonClicked_event -ea SilentlyContinue
#Unregister-Event -SourceIdentifier BalloonClicked_event -ea silentlycontinue
#Remove-Event BalloonClosed_event -ea SilentlyContinue
#Unregister-Event -SourceIdentifier BalloonClosed_event -ea silentlycontinue
Remove-Event Clicked_event -ea SilentlyContinue
Unregister-Event -SourceIdentifier Clicked_event -ea silentlycontinue
# Create the object and customize the message
$objNotifyIcon = New-Object System.Windows.Forms.NotifyIcon
$objNotifyIcon.Icon = [System.Drawing.SystemIcons]::Error

$objNotifyIcon.BalloonTipIcon = $Erra
$objNotifyIcon.BalloonTipTitle = $Nhost
$objNotifyIcon.BalloonTipText = $desc 
$objNotifyIcon.Text = “ZBX Notify”
# This will show or hide the icon in the system tray
$objNotifyIcon.Visible = $True
# Register a click event with action to take based on event, you can  use the following events BalloonTipClicked, BalloonTipClosed, Click
# System tray icon clicked – will hide the system tray icon
Register-ObjectEvent -InputObject $objNotifyIcon -EventName Click -SourceIdentifier Clicked_event -Action {[System.Windows.Forms.MessageBox]::Show(“Clicked”,”Information”);$objNotifyIcon.Visible = $False} | Out-Null
# This is the show the notification
$objNotifyIcon.ShowBalloonTip(1000)

Start-Sleep -s 300
$i++

}
}
