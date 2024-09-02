param(
$SN,
[switch]$ThisDevice
)	 
 
If($SN -ne $null){$serialNumber = $SN}

If($ThisDevice){
$serialNumber = (get-ciminstance win32_bios).SerialNumber
}

try{
	$Device_Info = invoke-restmethod "https://pcsupport.lenovo.com/us/en/api/v4/mse/getproducts?productId=$serialNumber"
	$Device_ID = $Device_Info.id
	$Warranty_url = "https://pcsupport.lenovo.com/us/en/products/$Device_ID/warranty"

	# $headers = @{
		# "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
	# }
}
Catch{
	write-warning "Can not get infomation for the serial number: $serialNumber"
	Break			
}

try{
$Web_Response = Invoke-WebRequest -Uri $Warranty_url -Method GET #-Headers $headers
}
Catch{
	write-warning "Can not get warranty info for the serial number: $serialNumber"
	Break
}

If($Web_Response.StatusCode -eq 200){
    $HTML_Content = $Web_Response.Content

    $Pattern_Status = '"warrantystatus":"(.*?)"'
    $Pattern_Status2 = '"StatusV2":"(.*?)"'
    $Pattern_StartDate = '"Start":"(.*?)"'
    $Pattern_EndDate = '"End":"(.*?)"'
    $Pattern_DeviceModel = '"Name":"(.*?)"'
		
    $Status_Matches = [regex]::Matches($HTML_Content, $Pattern_Status)
    $Statusv2_Matches = [regex]::Matches($HTML_Content, $Pattern_Status2)	
    $StartDate_Matches = [regex]::Matches($HTML_Content, $Pattern_StartDate)
    $EndDate_Matches = [regex]::Matches($HTML_Content, $Pattern_EndDate)
    $Model_Matches = [regex]::Matches($HTML_Content, $Pattern_DeviceModel)

    If($Status_Matches.Count -gt 0){
        $Status_Result = $Status_Matches[0].Groups[1].Value.Trim()
    }Else {
        $Status_Result = "Can not get status info"
    }
	
    If($Statusv2_Matches.Count -gt 0){
        $Statusv2_Result = $Statusv2_Matches[0].Groups[1].Value.Trim()
    }Else {
        $Statusv2_Result = "Can not get status info"
    }	
	
    If($StartDate_Matches.Count -gt 0){
        $StartDate_Result = $StartDate_Matches[0].Groups[1].Value.Trim()
    }

    If($EndDate_Matches.Count -gt 0){
        $EndDate_Result = $EndDate_Matches[0].Groups[1].Value.Trim()
    }

    If($Model_Matches.Count -gt 0){
        $Model_Result = $Model_Matches[0].Groups[1].Value.Trim()
    }	
}Else{
    Write-Output "Failed to retrieve warranty information. Status Code: $($response.StatusCode)"
}

$Warranty_Object = @()
$Properties = @{
SerialNumber = $serialNumber
Model = $Model_Result
Status = $Status_Result
StartDate = $StartDate_Result
EndDate = $EndDate_Result
IsActive = $Statusv2_Result
}
$Warranty_Object += New-Object -TypeName PSObject -Property $Properties | Select serialNumber,Model,Status,IsActive,StartDate,EndDate
$Warranty_Object                    


