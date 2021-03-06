function Set-TwinklyMode{
    [CmdletBinding()]
    param(
    [Parameter(Mandatory=$true)]
    [string]$IPAddress,
    [Parameter(Mandatory=$true)]
    [ValidateSet('off','on','movie')]
    [string]$Mode
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
            Switch ( $Mode ) {
                
                'On' { 
                    $Actions = @{'mode' = 'movie'}
                }
                'Off' { 
                    $Actions = @{'mode' = 'off'}
                }
                'movie' {
                    $Actions = @{'mode' = 'movie'}
                }
            }

            $ModeStatus = Invoke-RestMethod -Method Post -Uri "$uri/led/mode" -Headers $Header -Body ($Actions | ConvertTo-Json)
            if($ModeStatus.code -eq 1000){

            $Properties = [ordered]@{'Status' = 'Success'}

            $obj = New-Object -TypeName psobject -Property $Properties
            Write-Output $obj

            }
            else{
                throw "Error setting mode via API. Return Code: $($ModeStatus.Code)"
            }
        }
    }
    catch{
        Write-Error -Message $_.Exception.Message
    }
}