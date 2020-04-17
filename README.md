# PS_BallchasingAPIClient

A simple CLI client for the ballchasing.com API

## Usage prerequisites

A stable version of PowerShell 7.0+

## Usage

To start using this module

- run `Import-Module ballchasing-api-client.psm1` in the folder you downloaded the `.psm1` file to *or*
- Run `Import-Module $Path` and replace `$Path` with the path of the `.psm1` file

## Consider

The function `Get-SingleReplayContentByID` can *not* be used in a pipe.  
Use `Get-ReplayContentsByIDs` instead.

## Examples

To download all your replays:

`Get-MyReplayIDs -APIKey $YourAPIKey | Get-ReplayContentsByIDs -OutputFolder $DesiredOutputFolder`

where `$APIKey` and `$DesiredOutputFolder` are your API Key and desired output folder path, respectively.
