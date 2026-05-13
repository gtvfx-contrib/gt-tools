# This gets the status of the GlobalProtect VPN connection

$PANGP = Get-NetAdapter -InterfaceDescription "PANGP*"
$PANGP.Status
