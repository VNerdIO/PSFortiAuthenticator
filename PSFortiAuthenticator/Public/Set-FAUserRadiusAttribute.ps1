<#
    .SYNOPSIS
    Core function in PSFortiAuthenticator module to handle communication with the API.

    .DESCRIPTION
    Core function in PSFortiAuthenticator module to handle communication with the API.

    .EXAMPLE
    # Get localusers, skip the cert check
    $RadiusAttributes = @{
        "Framed-IP-Address" = "10.67.23.24"
        "Fortinet-Group-Name" = "StaticIPgroup"
        "Framed-IP-Netmask" = "255.255.255.0"
    }
    Set-FAUserRadiusAttribute -Server "fa.domain.com" -UserId 100 -RadiusAttributes

    .PARAMETER Server
    The fqdn/ip of the FortiAuthenticator appliance

    .PARAMETER UserId
    location of the resource you are working with. View the FortiAuthenticator docs (below).

    .PARAMETER RadiusAttributes
    Get/Post/...

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
Function Set-FAUserRadiusAttribute{
	[CmdletBinding()]
	Param([Parameter(Mandatory=$true)]
          [string]
		  $Server,
          [Parameter(Mandatory=$true)]
          [int]
		  $UserId,
          [Parameter(Mandatory=$true)]
          [string]
          [ValidateSet("Framed-IP-Address","Fortinet-Group-Name","Framed-IP-Netmask")]
          $RadiusAttribute,
          [Parameter(Mandatory=$true)]
          [string]
          $RadiusValue,
          [Parameter(Mandatory=$false)]
          [string]
          $RadiusVendor,
          [Parameter(Mandatory=$false)]
          [string]
          $RadiusOwner,
          [Parameter(Mandatory=$false)]
          [string]
		  $APIUser = $global:FAAPIUser,
          [Parameter(Mandatory=$false)]
          [string]
		  $APIKey = $global:FAAPIKey)
	
	begin{
        if(!$APIKey){ Throw "You need to include the secret." }
        if(!$APIUser){ Throw "You need to include a user." }
        $Resource = "localusers/$UserId/radiusattributes"
        $Method = "POST"

        $Data = @{}
        $Data.Add("attribute",$RadiusAttribute)
        $Data.Add("attr_val",$RadiusValue)
        if($Vendor){ $Data.Add("vendor",$RadiusVendor) }
        if($Owner){ $Data.Add("owner",$RadiusOwner) }

        $Json = $Data | ConvertTo-Json -Compress
        Write-Verbose $Json
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

            Write-FALog -Message "Starting to add attributes ($RadiusAttribute = $RadiusValue) for $UserId"
            $Results = Invoke-FAQuery @Params
            Write-Verbose $Results
            if($Results.radius_attributes){
                Write-Output $Results.radius_attributes
                Write-FALog -Message "Successfully added attributes for $UserId"
            } else {
                Write-Verbose $Results
                Write-Output $false
                Write-FALog -Message "Failed to add attributes ($RadiusAttribute = $RadiusValue) for $UserId ($Results)" -Level Error
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