# ANCHOR Main functions
function Get-ReplayIDs {
    param ([String]$APIKey, [Hashtable]$Parameters)

    $URIParameterString = ConvertTo-URIParameterString -Parameters $Parameters
    $ReplayWebRequest = @{
        Headers = "Authorization: $APIKey"
        Uri     = "https://ballchasing.com/api/replays$URIParameterString"
    }

    $Response = Invoke-WebRequest @ReplayWebRequest | ConvertTo-Json
    $Replays = $Response.list | ForEach-Object { return $_.id }
    
    $NextURL = $Response.next
    if ($null -ne $NextURL) {
        $Replays += Get-NextReplayIDs -APIKey $APIKey -Next $NextURL
    }

    return $Replays
}

function Get-MyReplayIDs {
    param ([String]$APIKey)

    $ReplayWebRequest = @{
        Headers = "Authorization: $APIKey"
        Uri     = "https://ballchasing.com/api/replays?uploader=me&count=200"
    }

    $Response = Invoke-WebRequest @ReplayWebRequest | ConvertFrom-Json
    $Replays = $Response.list | ForEach-Object { return $_.id }
    $NextURL = $Response.next
    if ($null -ne $NextURL) {
        $Replays += Get-NextReplayIDs -APIKey $APIKey -Next $NextURL
    }

    return $Replays
}

function Get-NextReplayIDs {
    param ([String]$APIKey, [String]$URL)

    $NextWebRequest = @{
        Headers = "Authorization: $APIKey"
        Uri     = $URL
    }

    $Response = Invoke-WebRequest @NextWebRequest | ConvertFrom-Json
    $Replays = $Response.list | ForEach-Object { return $_.id }
    $NextURL = $Response.next
    if ($null -ne $NextURL) {
        $Replays += Get-NextReplayIDs -APIKey $APIKey -Next $Next
    }

    return $Replays
}

function Get-SingleReplayContentByID {
    param ([String]$ReplayID, [String]$OutputFolder, [Int32]$Delay, [Switch]$SkipDelay, [Switch]$Overwrite)
    if ($null -eq $Delay) {
        $Delay = 500
    }
    
    $Success = $false
    $OutputPath = "$OutputFolder\$ReplayID.replay"
    $DataWebRequest = @{
        OutFile = $OutputPath
        Method  = "Post"
        Uri     = "https://ballchasing.com/dl/replay/$ReplayID"
    }

    if (Test-Path $OutputPath -and -not $Overwrite) {
        $UserChoice = Read-Host -Prompt "The file $OutputPath already exists. Overwrite it? [Y/n]"
        if ($UserChoice -match "n") {
            $Success = $true
        }
        else {
            Remove-Item $OutputPath
            Write-Host "Original file removed"
        }
    }

    while (-not $Success) {
        $StatusCode = (Invoke-WebRequest @DataWebRequest -PassThru).StatusCode

        if ($StatusCode -ne 200) {
            Remove-Item $OutputPath
            Start-Sleep -Milliseconds 60000
        }
        else {
            $Success = $true
            Write-Host "$ReplayID `t - Success"
        }
    }

    if (-not $SkipDelay) {
        Start-Sleep -Milliseconds $Delay
    }
}

function Get-ReplayContentsByIDs {
    param ([String]$OutputFolder, [Int32]$SafetyDelay)

    begin {
        $Counter = 0u
        $Timer = [System.Diagnostics.Stopwatch]::StartNew()
        $Timer.Stop()
    }

    process {
        $Counter += 1

        $Timer.Start()
        Get-SingleReplayContentByID -ReplayID $_ -OutputFolder $OutputFolder -SkipDelay
        $Timer.Stop()

        if ($Counter -ge 15 -and $Timer.ElapsedMilliseconds -le 60000) {
            Start-Sleep -Milliseconds ($SafetyDelay + 60000 - $Timer.ElapsedMilliseconds)
            $Counter = 0u
            $Timer.Reset()
        }
        
        elseif ($Timer.ElapsedMilliseconds -le 1000) {
            Start-Sleep -Milliseconds ($SafetyDelay + 1000 - $Timer.ElapsedMilliseconds)
            $Timer.Reset()
        }
    }
}

# ANCHOR Helper functions
function ConvertTo-URIParameterString {
    param ([Hashtable]$Parameters)

    $Keys = $Parameters.Keys
    $Result = $Keys | ForEach-Object { "$_=" + $Parameters.Item($_) }
    $Result = "?" + ($Result -join "&")

    return $Result
}

Export-ModuleMember -Function Get-ReplayIDs,
Get-MyReplayIDs,
Get-SingleReplayContentByID,
Get-ReplayContentsByIDs