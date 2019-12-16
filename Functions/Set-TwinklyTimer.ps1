function Set-TwinklyTimer{
    [CmdletBinding()]
    param(
    [Parameter(Mandatory=$true)]
    [string]$IPAddress,
    [Parameter(Mandatory=$true, ParameterSetName = 'Set')]
    [ValidatePattern("\d{2}:\d{2}")]
    [string]$TimeOn,
    [Parameter(Mandatory=$true, ParameterSetName = 'Set')]
    [ValidatePattern("\d{2}:\d{2}")]
    [string]$TimeOff,
    [Parameter(Mandatory=$true, ParameterSetName = 'Disable')]
    [switch]$Disable
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
    
    try{

        $token = Invoke-RestMethod -Method Post -Uri $URI/login -Headers $Header -Body ($LoginData | ConvertTo-Json)
        $Header = @{'Content-Type' = 'application/json'
                    'X-Auth-Token' = $token.authentication_token
                    }
        $ChallengeRepsonse = @{'CHALLENGE_RESPONSE' = $token.'challenge-response'}
        $Verify = Invoke-RestMethod -Method Post -Uri $URI/verify -Headers $Header -Body ($ChallengeRepsonse | ConvertTo-Json)

        if($Verify.code -eq 1000){

            if($Disable -eq $true){
                $TimeOnSeconds = -1
                $TimeOffSeconds = -1
            }            
            else{
                $TimeOnSeconds = ([TimeSpan]::Parse($TimeOn)).TotalSeconds
                $TimeOffSeconds = ([TimeSpan]::Parse($TimeOff)).TotalSeconds
            }

            $CurrentTime = (Get-date).TimeOfDay.TotalSeconds
            $Actions = @{'time_now' = $CurrentTime
                         'time_on' = $TimeOnSeconds
                         'time_off' = $TimeOffSeconds
                        }

            $Status = Invoke-RestMethod -Method Post -Uri "$URI/timer" -Headers $Header -Body ($Actions | ConvertTo-Json)
            if($Status.code -eq 1000){

                $Properties = [ordered]@{'Status' = 'Success'}
    
                $obj = New-Object -TypeName psobject -Property $Properties
                Write-Output $obj
    
            }
            else{
                throw "Error setting mode via API. Return Code: $($Status.Code)"
            }            
            
        }
        else{
            throw 'Error calling the Verifying the AuthToken'
        }
    }
    catch{
        Write-Error -Message $_.Exception.Message
    }
}