<#
    .SYNOPSIS
    Core function in PSFortiAuthenticator module to handle communication with the API.

    .DESCRIPTION
    Core function in PSFortiAuthenticator module to handle communication with the API.

    .EXAMPLE
    # Get radius, skip the cert check
    Set-FALocalGroupMembership -Server "fa.domain.com"

    .PARAMETER Server
    The fqdn/ip of the FortiAuthenticator appliance

    .PARAMETER Resource
    location of the resource you are working with. View the FortiAuthenticator docs (below).

    .PARAMETER Method
    Get/Post/...

    .PARAMETER APIUser
    API User. DON'T write scripts with the User in them. DO use environment variables/secrets

    .PARAMETER APIKey
    API Key. DON'T write scripts with the api key in them. DO use environment variables/secrets

    .PARAMETER SkipCertCheck
    Switch to disable stringent cert checking

    .OUTPUTS
    PSCustomObject with meta (Metadata) and objects (the actual objects)

    .NOTES

    .LINK
    https://docs.fortinet.com/document/fortiauthenticator/6.0.0/rest-api-solution-guide/927310/introduction
#>
Function Set-FALocalGroupMembership{
	[CmdletBinding()]
	Param([Parameter(Mandatory=$true)]
          [string]
		  $Server,
          [Parameter(Mandatory=$true)]
          [int]
		  $UserUri,
          [Parameter(Mandatory=$true)]
          [string]
		  $GroupUri,
          [Parameter(Mandatory=$false)]
          [string]
		  $APIUser = $global:FAAPIUser,
          [Parameter(Mandatory=$false)]
          [string]
		  $APIKey = $global:FAAPIKey)
	
	begin{
        if(!$APIKey){ Throw "You need to include the secret." }
        if(!$APIUser){ Throw "You need to include a user." }
        $Resource = "localgroup-memberships"
        $Method = "POST"
        $Json = @{"user"="$UserUri";"group"="$GroupUri"} | ConvertTo-Json -Compress
    }
	process{
		try{
            $Params = @{
                "Server"    = $Server
                "Resource"  = $Resource
                "Method"    = $Method
                "APIUser"   = $APIUser
                "APIKey"    = $APIKey
                "Data"      = $Json
            }

            $Results = Invoke-FAQuery @Params
            
            if($Results.objects){
                Write-Output $Results.objects
            } else {
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