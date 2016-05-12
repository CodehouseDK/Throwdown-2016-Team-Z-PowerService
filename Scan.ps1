$VerbosePreference = "Continue"

Add-Type -Path "$PSScriptRoot\lib\StackExchange.Redis.dll"

if($connection -eq $null)
{
    $connection = [StackExchange.Redis.ConnectionMultiplexer]::Connect("docker.local:6379")
}

if($admin -eq $null)
{
    $admin = Get-Credential
}

$subscriber = $connection.GetSubscriber()
$searcher = New-Object System.DirectoryServices.DirectorySearcher([adsi]"")
$searcher.Filter = "(objectClass=Computer)"
$computers = $searcher.FindAll().GetEnumerator() | ForEach-Object { $_.Properties.name }

while($true)
{
    $computers | % {
        $computerName = $_

        if(Test-Connection $computerName -Count 1 -ErrorAction SilentlyContinue)
        {
            Write-Verbose "Querying $computerName..."
    
            $data = Get-WmiObject Win32_Processor -ComputerName $computerName -Credential $admin -ErrorAction SilentlyContinue | % {
                Write-Output @{ CurrentClockSpeed = $_.CurrentClockSpeed;
                                MaxClockSpeed = $_.MaxClockSpeed;
                                CurrentVoltage = $_.CurrentVoltage;
                                NumberOfLogicalProcessors = $_.NumberOfLogicalProcessors;
                                LoadPercentage = $_.LoadPercentage;                                
                                ComputerName = $computerName;
                                Timestamp = [DateTime]::UtcNow.ToString("O") }
            }

            if($data -ne $null)
            {
                $json = $data | ConvertTo-Json -Compress
            
                $subscriber.Publish("powerservice", $json) | Out-Null

                Write-Host "Published: $json"
            }
        }
        else
        {        
            Write-Verbose "$computerName is offline."
        }    
    }
}