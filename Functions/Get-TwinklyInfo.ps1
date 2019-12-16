function Get-TwinklyInfo{
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
    
    try{

        $token = Invoke-RestMethod -Method Post -Uri $URI/login -Headers $Header -Body ($LoginData | ConvertTo-Json)
        $Header = @{'Content-Type' = 'application/json'
                    'X-Auth-Token' = $token.authentication_token
                    }
        $ChallengeRepsonse = @{'CHALLENGE_RESPONSE' = $token.'challenge-response'}
        $Verify = Invoke-RestMethod -Method Post -Uri $URI/verify -Headers $Header -Body ($ChallengeRepsonse | ConvertTo-Json)

        if($Verify.code -eq 1000){

            $Info = Invoke-RestMethod -Method Get -Uri "$URI/gestalt" -Headers $Header 

            if($Info.Code -eq 1000){
                $Properties = [ordered]@{'DeviceName' = $Info.device_name
                                        'ProductName' = $Info.product_name
                                        'HardwareVersion' = $Info.hardware_version
                                        'NumberOfLEDs' = $Info.number_of_led
                                        'LEDProfile' = $Info.led_profile
                                        'HardwareID' = $Info.hw_id
                                        'MACAddress' = $Info.mac
                                        'UUID' = $Info.UUID
                                        'UpTime' = [timespan]::frommilliseconds($Info.uptime).ToString()
                                        'ProductCode' = $Info.product_code
                                        'FirmwareFamily' = $Info.fw_family
                                        'FlashSize' = $Info.flash_size
                                        'BytesPerLED' = $Info.bytes_per_led
                                        'LEDType' = $Info.led_type
                                        'MaxSupportedLEDs' = $Info.max_supported_led
                                        'FrameRate' = $Info.frame_rate
                                        'MovieCapacity' = $Info.movie_capacity
                                        }
                $obj = New-Object -TypeName psobject -Property $Properties
                Write-Output $obj
            }
            else{
                throw "Error getting info from API."
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