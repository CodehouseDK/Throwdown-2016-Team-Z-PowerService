$VerbosePreference = "Continue"

Add-Type -Path "$PSScriptRoot\lib\StackExchange.Redis.dll"

function Get-ActiveDevelopers
{
    $searcher = New-Object System.DirectoryServices.DirectorySearcher([adsi]"LDAP://DK-DC1/OU=Codehouse,DC=ad,DC=codehouse,DC=com")
    $searcher.Filter = "(objectClass=User)"

    $developers = $searcher.FindAll().GetEnumerator() | ? { 
        $_.Properties.memberof -ne $null -and $_.Properties.lastlogon -gt 0 -and $_.Properties.memberof.Contains("CN=Developers,OU=Security Groups,OU=Codehouse,DC=ad,DC=codehouse,DC=com")
    } 

    $developers | % { 
        $lastlogin = [DateTime]::FromFileTime( [convert]::ToInt64($_.Properties.lastlogon, 10))

        Write-Verbose ($_.Properties.name)
        Write-Verbose $lastlogin
        Write-Verbose ($_.Properties.lastlogon)
        Write-Verbose "------"

        if($lastlogin.Date -eq [DateTime]::Now.Date) 
        {
            Write-Output ($_.Properties.samaccountname)
        }
    }
}

function Get-ComputerNames
{   
    $developers = Get-ActiveDevelopers
    $searcher = New-Object System.DirectoryServices.DirectorySearcher([adsi]"LDAP://DK-DC1/OU=Computers,OU=Codehouse,DC=ad,DC=codehouse,DC=com")
    $searcher.Filter = "(objectClass=Computer)"

    $computers = $searcher.FindAll().GetEnumerator() | ? { $_ -ne $null } | % { $_.Properties.name }
    $computers | % {
        $computerName = $_
        $isActive = $false

        $developers | % {
            $user = $_
            
            if($computerName.StartsWith("DK-$user", [System.StringComparison]::OrdinalIgnoreCase))
            {                
                $isActive = $true
            }
           
        } 

        if($isActive)
        {
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
        else
        {
            Write-Verbose "$computerName was not a active workstation..."
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

    $measurement = @{ AvailableCores = 0;  AvailableMhz = 0; AverageLoad = 0; Timestamp = [DateTime]::Now.ToString("O"); Computers = $entries.Count }

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