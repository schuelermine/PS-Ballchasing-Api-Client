# ballchasing-api-client-ps
A simple CLI client for the ballchasing.com API

## Usage prerequisites

- a current-enough version of
  - PowerShell *or*
  - Windows PowerShell *or*
  - PowerShell Core
- an installation of cURL
  - that is available in the console (in your `$env:Path`)

Recommended:

- a stable version of
  - PowerShell 7.0+ *or*
  - Windows PowerShell 5.0+ *or*
  - PowerShell Core 6.0+

## Example usage

To download all your replays:

`Get-MyReplayIDs -APIKey $YourAPIKey | Get-ReplayContentsByIDs -OutputPath $DesiredOutputPath`

where `$APIKey` and `$DesiredOutputPath` are your API Key and desired output folder path, respectively.