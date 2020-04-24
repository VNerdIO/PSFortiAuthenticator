<#
    .SYNOPSIS
    Core function in PSFortiAuthenticator module to handle communication with the API.

    .DESCRIPTION
    Core function in PSFortiAuthenticator module to handle communication with the API.

    .EXAMPLE
    # Create a user and email the random generated password
    $Fields = @{"username"="dwight";"email"="dwight@theoffice.com"}
    New-FAUser -Server "fa.domain.com" -Fields $Fields

    .PARAMETER Server
    The fqdn/ip of the FortiAuthenticator appliance

    .PARAMETER Fields
    Fields you want to update in a hashtable. Username is REQUIRED. If Password is not included, Email is required.

    $Fields = @{
        "username" = "pam"
        "email" = "pam@theoffice.com"
    }

    .PARAMETER APIUser
    API User. DON'T write scripts with the User in them. DO use environment variables/secrets

    .PARAMETER APIKey
    API Key. DON'T write scripts with the api key in them. DO use environment variables/secrets

    .OUTPUTS
    PSCustomObject with meta (Metadata) and objects (the actual objects)

    .NOTES

    .LINK
    https://docs.fortinet.com/document/fortiauthenticator/6.0.0/rest-api-solution-guide/829822/local-users-localusers
#>
Function New-FAUser{
	[CmdletBinding()]
	Param([Parameter(Mandatory=$true)]
          [string]
		  $Server,
          [Parameter(Mandatory=$true)]
          [hashtable]
		  $Fields,
          [Parameter(Mandatory=$false)]
          [string]
		  $APIUser = $global:FAAPIUser,
          [Parameter(Mandatory=$false)]
          [string]
		  $APIKey = $global:FAAPIKey)
	
	begin{
        if(!$APIKey){ Throw "You need to include the secret." }
        if(!$APIUser){ Throw "You need to include a user." }
        $Resource = "localusers"
        $Method = "POST"

        # Remove empty values
        $Fields.GetEnumerator() | Where-Object {-not $_.Value} | % { $Fields.Remove($_.Name) }

        # Maker sure the mobile/phone numbers are 1-XXXYYYZZZZ
        $Fields['username'] = $Fields['username'].ToLower()
        if($Fields['mobile_number']){
            $mobile_number = $Fields['mobile_number'] -Replace "\D",""
            if($mobile_number.Length -eq 10){
                $Fields['mobile_number'] = "1-$mobile_number"
            } elseif($mobile_number.Length -eq 11){
                $mobile_number = $mobile_number -replace "^1","1-"
                $Fields['mobile_number'] = $mobile_number
            }
        }
        if($Fields['phone_number']){
            $phone_number = $Fields['phone_number'] -Replace "\D",""
            if($phone_number.Length -eq 10){
                $Fields['phone_number'] = "1-$phone_number"
            } elseif($phone_number.Length -eq 11){
                $phone_number = $phone_number -replace "^1","1-"
                $Fields['phone_number'] = $phone_number
            }
        }
    }
	process{
		try{
            Write-FALog -Message "Starting to add $($Fields.username)"
            $Json = ($Fields | ConvertTo-Json -Compress)
            Write-Verbose $Json

            $Params = @{
                "Server"    = $Server
                "Resource"  = $Resource
                "Method"    = $Method
                "APIUser"   = $APIUser
                "APIKey"    = $APIKey
                "Data"      = $Json
            }
            $Results = Invoke-FAQuery @Params
            
            if($Results.username){
                $ResultsJson = $Results | ConvertTo-Json
                Write-FALog -Message "Successfully added $($Fields.username) - $ResultsJson"
                Write-Output $Results
            } else {
                Write-Verbose $Results
                Write-FALog -Message "Failed to add $($Fields.username): $Results ($Json)" -Level "Error"
                Write-Output $false
            }
        }
		catch{
			$ErrorMessage = $_.Exception.Message
			$FailedItem = $_.Exception.ItemName
			
			Write-Output "$FailedItem - $ErrorMessage"
			Return $False
		}
		finally{}
	}
	end{}
}