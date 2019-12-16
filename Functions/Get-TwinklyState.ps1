function Get-TwinklyState{
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

        Invoke-RestMethod -Method Get -Uri "$uri/led/mode" -Headers $Header
        
    }
}