function Add-Delays {
    param (
        [ScriptBlock]$ScriptBlock,
        [Hashtable]$Delays,
        [Int32]$BaseDelay
    )

    begin {
        $Trackers = @{ }
        foreach ($Key in $Delays.Keys) {
            $IntKey = $Key -as [Int32]
            if ($null -eq $IntKey) {
                throw "$Key couldn't be converted to Int32"
            }
            elseif ($IntKey -le 0) {
                throw "$Key is not a positive number"
            }

            $IntValue = $Delays[$Key] -as [UInt32]
            if ($null -eq $IntValue) {
                throw "$($Delays[$Key]) couldn't be converted to UInt32"
            }
            elseif ($IntValue -le 0) {
                throw "$($Delays[$Key]) is not a positive number"
            }
        }

        foreach ($Key in $Delays.Keys) {
            $Trackers += @{
                $Key = @{
                    Timer = [System.Diagnostics.Stopwatch]::new()
                    Counter = [UInt64]1
                }
            }
        }
    }

    process {
        foreach ($Key in $Delays.Keys) {
            # Write-Host "D `t $Key `t $($Trackers[$Key].Timer.elapsedMilliseconds) ms `t $($Trackers[$Key].Counter)"
        }

        foreach ($Key in $Delays.Keys) {
            if (
                $Trackers[$Key].Timer.elapsedMilliseconds -gt
                [Int32]$Key
            ) {
                $Trackers[$Key].Timer.Reset()
                $Trackers[$Key].Counter = [UInt64]0
            }
        }

        foreach ($Key in $Delays.Keys) {
            $Trackers[$Key].Timer.Start()
        }

        $Wait = 0

        foreach ($Key in $Delays.Keys) {
            $Elapsed = $Trackers[$Key].Timer.elapsedMilliseconds

            if (
                $Elapsed -lt [Int32]$Key -and
                $Trackers[$Key].Counter -gt $Delays[$Key]
            ) {
                $RemainingTime = [Int32]$Key - $Elapsed
                $Wait = [Math]::Max($Wait, $RemainingTime)

                # Write-Host "A `t $Key `t $Elapsed `t $RemainingTime"
            }
        }

        foreach ($Key in $Delays.Keys) {
            $Trackers[$Key].Timer.Start()
        }

        # Write-Host "B `t $Wait `t $($Wait + $BaseDelay)"

        Start-Sleep -Milliseconds ($Wait + $BaseDelay)

        foreach ($Key in $Delays.Keys) {
            $Trackers[$Key].Timer.Stop()
        }

        $ReturnValue = & $ScriptBlock $_

        # Write-Host "C `t $_ `t $ReturnValue"
        
        foreach ($Key in $Delays.Keys) {
            # Write-Host "D `t $Key `t $($Trackers[$Key].Timer.elapsedMilliseconds) ms `t $($Trackers[$Key].Counter)"
        }

        foreach ($Key in $Delays.Keys) {
            $Trackers[$Key].Timer.Stop()
        }

        if ($ReturnValue) {
            foreach ($Key in $Delays.Keys) {
                $Trackers[$Key].Counter += 1
            }
        }
    }

    end {

    }
}