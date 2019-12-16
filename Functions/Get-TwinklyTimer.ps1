function Get-TwinklyTimer{
    [CmdletBinding()]
    param(
    [Parameter(Mandatory=$true)]
    [string]$IPAddress
    )
       
    $String = @()
    For ($i=1; $i -le 32; $i++) {
        $String += [CHAR][BYTE](get-random -max 127 -min 33)
    }
    
    $Bytes  = [System.Text.Encoding]::UTF8.GetBytes(-join $String)
    $Challenge = [System.Convert]::ToBase64String($Bytes)

    $URI = "http://$($IPAddress)/xled/v1"
    $Header = @{'Content-Type' = 'application/json'}
    $LoginData = @{'challenge' = $Challenge}
    
    $token = Invoke-RestMethod -Method Post -Uri $URI/login -Headers $Header -Body ($LoginData | ConvertTo-Json)
    $Header = @{'Content-Type' = 'application/json'
                 'X-Auth-Token' = $token.authentication_token
                }
    $ChallengeRepsonse = @{'CHALLENGE_RESPONSE' = $token.'challenge-response'}
    $Verify = Invoke-RestMethod -Method Post -Uri $URI/verify -Headers $Header -Body ($ChallengeRepsonse | ConvertTo-Json)

    if($Verify.code -eq 1000){

        $Timer = Invoke-RestMethod -Method Get -Uri "$URI/timer" -Headers $Header 

        $TimeNow =  [timespan]::fromseconds($Timer.time_now)
        $TimeNowFormatted = ("{0:hh\:mm\:ss}" -f $TimeNow)
       

        if($timer.time_on -lt 0){

            $TimeOnFormatted = 'NotSet'

        }
        else{

            $TimeOn =  [timespan]::fromseconds($timer.time_on)
            $TimeOnFormatted = ("{0:hh\:mm\:ss}" -f $TimeOn)
        }

        if($timer.time_off -lt 0){

            $TimeOffFormatted = 'NotSet'

        }
        else{

            $TimeOff =  [timespan]::fromseconds($timer.time_off)
            $TimeOffFormatted = ("{0:hh\:mm\:ss}" -f $TimeOff)
        }

        $Properties = [ordered]@{'CurrentTime' = $TimeNowFormatted
                                 'TurnOn' = $TimeOnFormatted
                                 'TurnOff' = $TimeOffFormatted
        }

        $obj = New-Object -TypeName psobject -Property $Properties
        Write-Output $obj
    }
}