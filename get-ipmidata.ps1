<#	
    .NOTES
	=========================================================================================================
        Filename:	get-ipmidata.ps1
        Version:	0.1 
        Created:	12/05/2016
    Requires:       IPMIUtil.exe for Windows (http://ipmiutil.sourceforge.net/)
	Requires:       curl.exe for Windows (https://curl.haxx.se/download.html)
	Requires:       InfluxDB 0.9.4 or later.  The latest is preferred.
        Requires:       Grafana 2.5 or later.  The latest is preferred.
        Prior Art:      Based on the linux script by Curt Dennis (https://git.denlab.io/dencur/grafana_scripts_public/blob/master/healthmon.sh)
        
	Author:         Marc Dekeyser (a.k.a. Toasterlabs)
	Blog:	https://geekswithblogs.net/marcde
	=========================================================================================================
	
    .SYNOPSIS
	Gathers IPMI data using IPMI Util and writes it to InfluxDB

    .DESCRIPTION
        This script supports InfluxDB 0.9.4 and later (including the latest 0.10.x).
        Please note that we use curl.exe for InfluxDB line protocol writes.  This means you must
        download curl.exe for Windows in order for Powershell to write to InfluxDB. In addition it requires
        IPMIUtil to retrieve the data.

    .HOWTO
        Change the pluginpath, user, pass, host and hostname to match your environment. At the end of the script, change
        InfluxDB-IP, InfluxDB-port & InfluxDB-Name to the values of your Influx DB Server and DB Name
    
    .EXAMPLE
        .\get-ipmidata.ps1

    .FUTURE
        I should really make use of those variables...


#>


# Variables
$pluginPath = "C:\ipmiutil"
$IPMIUser = "ADMIN"
$IPMIPass = "ADMIN"
$IPMIHost = "192.168.1.21"
$IPMIHostName = "Galactica"

# Influx Setup
    $InfluxStruct = New-Object -TypeName PSObject -Property @{
	    CurlPath = 'C:\Windows\System32\curl.exe';
        #InfluxDbServer = 'InfluxDB-IP'; #IP Address
        #InfluxDbPort = InfluxDB-port;
        #InfluxDbName = 'InfluxDB-Name';
        #InfluxDbUser = '';
        #InfluxDbPassword = '';
        #MetricsString = '' #emtpy string that we populate later.
    }

# Collecting data
$results = cmd /c "$PluginPath\ipmiutil.exe" sensor -N $IPMIHost -U $IPMIUser -P $IPMIPass -s

# Splitting data
$CPUTemp = (($results | select-string "CPU Temp").line.split('|')[-1] -replace '\s+') -replace ".{1}$"
$SystemTemp = (($results | select-string "System Temp").line.split('|')[-1] -replace '\s+') -replace ".{1}$"
$PeriphTemp = (($results | select-string "Peripheral Temp").line.split('|')[-1] -replace '\s+') -replace ".{1}$"
$PCHTemp = (($results | select-string "PCH Temp").line.split('|')[-1] -replace '\s+') -replace ".{1}$"
$FAN1 = (($results | select-string "FAN 1").line.split('|')[-1] -replace '\s+') -replace ".{3}$"
$FAN2 = (($results | select-string "FAN 2").line.split('|')[-1] -replace '\s+')-replace ".{3}$"

[int64]$timestamp = (([datetime]::UtcNow)-(Get-Date -Date "1/1/1970")).TotalMilliseconds * 1000000 #nanoseconds since Unix epoch

# Writing to InfluxDB = Split this up since it wrecked my tiny little brain
$CurlCommand  = "$($InfluxStruct.CurlPath) -i -XPOST http://InfluxDB-IP:InfluxDB-port/write?db=InfluxDB-Name --data-binary 'Health_Data,host=$IPMIHostName,sensor=CpuTemp value=$CPUTemp'"
Invoke-Expression -Command $CurlCommand 2>&1

$CurlCommand  = "$($InfluxStruct.CurlPath) -i -XPOST http://InfluxDB-IP:InfluxDB-port/write?db=InfluxDB-Name --data-binary 'Health_Data,host=$IPMIHostName,sensor=SystemTemp value=$SystemTemp'"
Invoke-Expression -Command $CurlCommand 2>&1

$CurlCommand  = "$($InfluxStruct.CurlPath) -i -XPOST http://InfluxDB-IP:InfluxDB-port/write?db=InfluxDB-Name --data-binary 'Health_Data,host=$IPMIHostName,sensor=PeriphTemp value=$PeriphTemp'"
Invoke-Expression -Command $CurlCommand 2>&1

$CurlCommand  = "$($InfluxStruct.CurlPath) -i -XPOST http://InfluxDB-IP:InfluxDB-port/write?db=InfluxDB-Name --data-binary 'Health_Data,host=$IPMIHostName,sensor=PCHTemp value=$PCHTemp'"
Invoke-Expression -Command $CurlCommand 2>&1

$CurlCommand  = "$($InfluxStruct.CurlPath) -i -XPOST http://InfluxDB-IP:InfluxDB-port/write?db=InfluxDB-Name --data-binary 'Health_Data,host=$IPMIHostName,sensor=FAN1 value=$FAN1'"
Invoke-Expression -Command $CurlCommand 2>&1

$CurlCommand  = "$($InfluxStruct.CurlPath) -i -XPOST http://InfluxDB-IP:InfluxDB-port/write?db=InfluxDB-Name --data-binary 'Health_Data,host=$IPMIHostName,sensor=FAN2 value=$FAN2'"
Invoke-Expression -Command $CurlCommand 2>&1