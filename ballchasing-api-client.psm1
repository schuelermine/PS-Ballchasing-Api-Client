# ANCHOR Main functions
function Test-APIKey {
    param ([String]$APIKey, [Switch]$ForceNoAPIKey)

    if ([String]::IsNullOrEmpty($APIKey) -and -not $ForceNoAPIKey) {
        Write-Host "No API key"
        return $false
    }

    if ($ForceNoAPIKey) {
        $Headers = @{ }
    }
    else {
        $Headers = @{ Authorization = $APIKey }
    }

    $Request = @{
        Headers = $Headers
        Uri     = "https://ballchasing.com/api/"
    }

    try {
        $Response = Invoke-WebRequest -SkipHttpErrorCheck @Request
        $StatusCode = $Response.StatusCode
    }
    catch {
        Write-Host "Invalid API key format"
        return $false
    }
    
    if ($StatusCode -ne 200) {
        try {
            $Exception = ($Response.Content | ConvertFrom-Json).error

            Write-Host "Ballchasing API returned this error:"
            Write-Host $Exception

            return $false
        }
        catch {
            Write-Host "No error returned, but the status code was not 200"
            Write-Host "Status code: $StatusCode"

            return $false
        }
    }
    else {
        return $true
    }
}

function Get-ReplayIDs {
    param ([String]$APIKey, [Hashtable]$Parameters)

    $IsValid = Test-APIKey -APIKey $APIKey
    if (-not $IsValid) {
        return $null
    }

    $URIParameterString = ConvertTo-URIParameterString -Parameters $Parameters
    $ReplayWebRequest = @{
        Headers = @{ Authorization = $APIKey }
        Uri     = "https://ballchasing.com/api/replays$URIParameterString"
    }

    $Response = Invoke-WebRequest @ReplayWebRequest | ConvertTo-Json
    $Replays = $Response.list | ForEach-Object { return $_.id }
    
    $NextURL = $Response.next
    if ($null -ne $NextURL) {
        $Replays += Get-NextReplayIDs -APIKey $APIKey -URL $NextURL
    }

    return $Replays
}

function Get-MyReplayIDs {
    param ([String]$APIKey)

    $IsValid = Test-APIKey -APIKey $APIKey
    if (-not $IsValid) {
        return $null
    }

    $ReplayWebRequest = @{
        Headers = @{ Authorization = $APIKey }
        Uri     = "https://ballchasing.com/api/replays?uploader=me&count=200"
    }

    $Response = Invoke-WebRequest @ReplayWebRequest | ConvertFrom-Json
    $Replays = $Response.list | ForEach-Object { return $_.id }
    $NextURL = $Response.next
    if ($null -ne $NextURL) {
        $Replays += Get-NextReplayIDs -APIKey $APIKey -URL $NextURL
    }

    return $Replays
}

function Get-NextReplayIDs {
    param ([String]$APIKey, [String]$URL)

    $NextWebRequest = @{
        Headers = @{ Authorization = $APIKey }
        Uri     = $URL
    }

    $Response = Invoke-WebRequest @NextWebRequest | ConvertFrom-Json
    $Replays = $Response.list | ForEach-Object { return $_.id }
    $NextURL = $Response.next
    if ($null -ne $NextURL) {
        $Replays += Get-NextReplayIDs -APIKey $APIKey -URL $NextURL
    }

    return $Replays
}

function Get-SingleReplayContentByID {
    param ([String]$ReplayID, [String]$OutputFolder, [Int32]$Delay, [Switch]$SkipDelay, [Switch]$Overwrite, [Switch]$KeepFiles)
    if (-not $PSBoundParameters.ContainsKey("Delay")) {
        $Delay = 500
    }
    
    $DidRequest = $false
    $Done = $false
    $OutputPath = "$OutputFolder\$ReplayID.replay"
    $DataWebRequest = @{
        OutFile = $OutputPath
        Method  = "Post"
        Uri     = "https://ballchasing.com/dl/replay/$ReplayID"
    }

    
    if ((Test-Path $OutputPath)) {
        if ($KeepFiles) {
            $Remove = $false
        }
        elseif ($Overwrite) {
            $Remove = $true
        }
        elseif (-not $Overwrite -and -not $KeepFiles) {
            $UserChoice = Read-Host -Prompt "The file $OutputPath already exists. Overwrite it? [Y/n]"
            if ($UserChoice -match "n") {
                $Remove = $false
            }
            else {
                $Remove = $true
            }
        }

        if ($Remove) {
            Remove-Item $OutputPath
            Write-Host "Exising file removed"
        }
        else {
            $Done = $true
            Write-Host "Skipping existing file"
        }
    }

    while (-not $Done) {
        $StatusCode = (Invoke-WebRequest -SkipHttpErrorCheck -PassThru @DataWebRequest).StatusCode

        $DidRequest = $true

        if ($StatusCode -ne 200) {
            Write-Host "Failed getting replay, retrying in 60 seconds"
            if ((Test-Path $OutputPath)) {
                Remove-Item $OutputPath
            }
            Start-Sleep -Milliseconds 60000
        }
        else {
            $Done = $true
            Write-Host "$ReplayID `t - Success"
        }
    }

    if (-not $SkipDelay) {
        Start-Sleep -Milliseconds $Delay
    }

    return $DidRequest
}

function Get-ReplayContentsByIDs {
    param ([String]$OutputFolder, [Int32]$SafetyDelay, [Switch]$KeepFiles)

    begin {
        $Counter = 0u
        $Timer = [System.Diagnostics.Stopwatch]::StartNew()
        $Timer.Stop()
    }

    process {
        $Timer.Start()
        $DidRequest =
            Get-SingleReplayContentByID -ReplayID $_ -OutputFolder $OutputFolder -SkipDelay -KeepFiles:$KeepFiles
        $Timer.Stop()

        if ($DidRequest) {
            $Counter += 1
        }

        if ($Counter -ge 15 -and $Timer.ElapsedMilliseconds -le 60000) {
            Start-Sleep -Milliseconds ($SafetyDelay + 60000 - $Timer.ElapsedMilliseconds)
            $Counter = 0u
        }
        elseif ($Timer.ElapsedMilliseconds -le 1000) {
            Start-Sleep -Milliseconds ($SafetyDelay + 1000 - $Timer.ElapsedMilliseconds)
        }

        $Timer.Reset()
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

Export-ModuleMember -Function Test-APIKey,
    Get-ReplayIDs,
    Get-MyReplayIDs,
    Get-SingleReplayContentByID,
    Get-ReplayContentsByIDs