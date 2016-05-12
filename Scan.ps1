$VerbosePreference = "Continue"

Add-Type -Path "$PSScriptRoot\lib\StackExchange.Redis.dll"

function Get-ComputerNames
{   
    $searcher = New-Object System.DirectoryServices.DirectorySearcher([adsi]"LDAP://DK-DC1/OU=Computers,OU=Codehouse,DC=ad,DC=codehouse,DC=com")
    $searcher.Filter = "(objectClass=Computer)"

    $computers = $searcher.FindAll().GetEnumerator() | ? { $_ -ne $null } | % { $_.Properties.name }
    $computers | % {
        $computerName = $_
    
        if(Test-Connection $computerName -Count 1 -ErrorAction SilentlyContinue) 
        {
            Write-Output $computerName

            Write-Host "$computerName is online."
        }
        else
        {        
            Write-Verbose "$computerName was offline..."
        }  
    }
}

if($connection -eq $null)
{
    $connection = [StackExchange.Redis.ConnectionMultiplexer]::Connect("docker.local:6379")
}

if($admin -eq $null)
{
    $admin = Get-Credential
}

if($computers -eq $null)
{
    $computers = Get-ComputerNames
}

$loops = 0

while($true)
{
    if($loops -gt 100)
    {
        Write-Verbose "Time to refresh the list of online computers..."
        
        $computers = Get-ComputerNames
    }
    
    $entries = @()
    $computers | select -first 1000 | % {
        $computerName = $_

        Write-Verbose "Querying $computerName..."
    
        Get-WmiObject Win32_Processor -ComputerName $computerName -Credential $admin -ErrorAction SilentlyContinue | % {
            $entries += @{ CurrentClockSpeed = $_.CurrentClockSpeed;
                            MaxClockSpeed = $_.MaxClockSpeed;
                            CurrentVoltage = $_.CurrentVoltage;
                            NumberOfLogicalProcessors = $_.NumberOfLogicalProcessors;
                            LoadPercentage = $_.LoadPercentage;                                
                            ComputerName = $computerName;
                            Timestamp = [DateTime]::UtcNow.ToString("O") }
        }
    }

    $measurement = @{ AvailableCores = 0;  AvailableMhz = 0; AverageLoad = 0; Timestamp = [DateTime]::UtcNow.ToString("O"); Computers = $entries.Count }

    $entries | % {
        $measurement.AvailableCores += $_.NumberOfLogicalProcessors
        $measurement.AvailableMhz += $_.MaxClockSpeed
    }

    $measurement.AverageLoad = $entries | % { $_.LoadPercentage } | measure -Average | % { $_.Average }

    $json = $measurement | ConvertTo-Json -Compress
          
    $connection.GetSubscriber().Publish("powerservice", $json) | Out-Null

    Write-Host "Published: $json"
        
    $loops++
}