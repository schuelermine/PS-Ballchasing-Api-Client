# ANCHOR Main functions

function Get-ReplayIDs {
    param ([String]$APIKey, [Hashtable]$Parameters)
    $URIParameterString = ConvertTo-URIParameterString -Parameters $Parameters
    $Response =
        cURL "https://ballchasing.com/api/replays$URIParameterString" `
        -H "Authorization: $APIKey" | ConvertFrom-Json
    $Replays = $Response.list | ForEach-Object { return $_.id }
    $NextURL = $Response.next
    if ($null -ne $NextURL) {
        $Replays += Get-NextReplayIDs -APIKey $APIKey -Next $NextURL
    }
    return $Replays
}

function Get-MyReplayIDs {
    param ([String]$APIKey)
    $Response =
        cURL "https://ballchasing.com/api/replays?uploader=me&count=200" -H "Authorization: $APIKey" | ConvertFrom-Json
    $Replays = $Response.list | ForEach-Object { return $_.id }
    $NextURL = $Response.next
    if ($null -ne $NextURL) {
        $Replays += Get-NextReplayIDs -APIKey $APIKey -Next $NextURL
    }
    return $Replays
}

function Get-NextReplayIDs {
    param ([String]$APIKey, [String]$URL)
    $Response = cURL $URL -H "Authorization: $APIKey" | ConvertFrom-Json
    $Replays = $Response.list | ForEach-Object { return $_.id }
    $NextURL = $Response.next
    if ($null -ne $NextURL) {
        $Replays += Get-NextReplayIDs -APIKey $APIKey -Next $Next
    }
    return $Replays
}

function Get-SingleReplayContentByID {
    param ([String]$ReplayID, [String]$OutputFolder, [Int32]$Delay)
    if ($null -eq $Delay) {
        $Delay = 500
    }
    $OutputPath = "$OutputFolder\$ReplayID.replay"
    cURL -X POST "https://ballchasing.com/dl/replay/$ReplayID" --output $OutputPath
    # TODO Test-ReplayIntegrity -File -OutputPath
    Start-Sleep -Milliseconds $Delay
}

function Get-ReplayContentsByIDs {
    param ([String]$OutputPath)
    begin {
        $Counter = 0u
        $Timer = [System.Diagnostics.Stopwatch]::StartNew()
        $Timer.Stop()
    }
    process {
        $Timer.Start
        Get-SingleReplayContentByID -ReplayID $_ -OutputPath $OutputPath
        $Timer.Stop()
        if ($Counter -ge 15 -and $Timer.ElapsedMilliseconds -le 60000) {
            Start-Sleep -Milliseconds (60000 - $Timer.ElapsedMilliseconds)
            $Counter = 0u
            $Timer.Reset()
        } elseif ($Timer.ElapsedMilliseconds -le 1000) {
            Start-Sleep -Milliseconds (1000 - $Timer.ElapsedMilliseconds)
            $Counter = 0u
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
