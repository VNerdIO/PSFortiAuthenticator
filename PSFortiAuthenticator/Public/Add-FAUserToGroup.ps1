<#
    .SYNOPSIS
    Core function in PSFortiAuthenticator module to handle communication with the API.

    .DESCRIPTION
    Core function in PSFortiAuthenticator module to handle communication with the API.

    .EXAMPLE
    # Get radius, skip the cert check
    Get-FALocalGroupMembership -Server "fa.domain.com"

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
    https://docs.fortinet.com/document/fortiauthenticator/6.1.0/rest-api-solution-guide/127943/user-groups-usergroups
#>
Function Add-FAUserToGroup{
	[CmdletBinding()]
	Param([Parameter(Mandatory=$true)]
          [string]
		  $Server,
          [Parameter(Mandatory=$true)]
          [string]
		  $UserName,
          [Parameter(Mandatory=$true)]
          [string]
		  $GroupName,
          [Parameter(Mandatory=$false)]
          [string]
		  $APIUser = $global:FAAPIUser,
          [Parameter(Mandatory=$false)]
          [string]
		  $APIKey = $global:FAAPIKey)
	
	begin{
        if(!$APIKey){ Throw "You need to include the secret." }
        if(!$APIUser){ Throw "You need to include a user." }
        $Resource = "usergroups"
        $Method = "PATCH"
    }
	process{
		try{
            $Params = @{
                "Server"    = $Server
                "Resource"  = $Resource
                "Method"    = $Method
                "APIUser"   = $APIUser
                "APIKey"    = $APIKey
            }
            $GetParams = @{
                "Server"    = $Server
                "APIUser"   = $APIUser
                "APIKey"    = $APIKey
            }
            Write-Verbose $Params | ConvertTo-Json
            $Group = Get-FAUserGroup @GetParams | where name -eq "$GroupName"
            $User = Get-FAUser @GetParams | where username -eq "$UserName"

            if($User.resource_uri -AND $Group.resource_uri){
                $Params.Remove("Resource")
                $GroupResourceUri = $Group.resource_uri -replace "/api/v1/",""
                $Params.Add("Resource",$GroupResourceUri)
                $CurrentGroupUsers = $Group.Users
                $CurrentGroupUserCount = $Group.Users.Count
                $UserResource = $User.resource_uri
                $NewGroupUsers = $CurrentGroupUsers + $UserResource

                if($NewGroupUsers.Count -gt $CurrentGroupUserCount){
                    Write-Verbose "New Group count ($($NewGroupUsers.Count)) is greater than existing ($CurrentGroupUserCount)"
                    $NewGroupUsersJson = @{"users"=$NewGroupUsers} | ConvertTo-Json -Compress
                    $Params.Add("Data",$NewGroupUsersJson)
                    Write-Verbose $NewGroupUsersJson
                    $ParamJson = $Params | ConvertTo-Json
                    Write-Verbose $ParamJson

                    $Results = Invoke-FAQuery @Params
                    
                    if($Results){
                        Write-Output $Results
                    } else {
                        Write-Output $false
                    }
                } else {
                    Throw "New Group count ($($NewGroupUsers.Count)) is not greater than existing ($CurrentGroupUserCount)."
                }
            } else {
                Throw "No group by that name - $GroupName or Username $UserName"
            }
        }
		catch{
			$ErrorMessage = $_.Exception.Message
			
			Write-Output $ErrorMessage
			Return $False
		}
		finally{}
	}
	end{}
}