<#
    .SYNOPSIS
    Core function in PSFortiAuthenticator module to handle communication with the API.

    .DESCRIPTION
    Core function in PSFortiAuthenticator module to handle communication with the API.

    .EXAMPLE
    # Get localusers, skip the cert check
    Invoke-FAQuery -Server "fa.domain.com" -Resource "localusers" -Method "GET" -Verbose -SkipCertCheck

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
Function Invoke-FAQuery{
	[CmdletBinding()]
	Param([Parameter(Mandatory=$true)]
          [string]
		  $Server,
          [Parameter(Mandatory=$true)]
          [string]
		  $Resource,
          [string]
		  [Parameter(Mandatory=$true)]
		  [ValidateSet("GET","PUT","PATCH","POST","DELETE")]
          $Method,
          [Parameter(Mandatory=$false)]
          [string]
		  $Data,
          [Parameter(Mandatory=$false)]
          [string]
		  $APIUser = $global:FAAPIUser,
          [Parameter(Mandatory=$false)]
          [string]
		  $APIKey = $global:FAAPIKey,
          [Parameter(Mandatory=$false)]
          [switch]
		  $SkipCertCheck)
	
	begin{
        if($SkipCertCheck){
        add-type @"
            using System.Net;
            using System.Security.Cryptography.X509Certificates;
            public class TrustAllCertsPolicy : ICertificatePolicy {
                public bool CheckValidationResult(
                    ServicePoint srvPoint, X509Certificate certificate,
                    WebRequest request, int certificateProblem) {
                    return true;
                }
            }
"@
        [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        }

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        if(!$APIKey){ Throw "You need to include the secret." }
        if(!$APIUser){ Throw "You need to include a user." }
        $AuthString = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $APIUser,$APIKey)))
        $Headers = @{Authorization=("Basic {0}" -f $AuthString)}
        $Limit = 1000
        if($Method -eq "GET"){
            $BaseUrl = "https://$Server/api/v1/$($Resource)/?format=json&limit=$Limit"
        } else {
            $BaseUrl = "https://$Server/api/v1/$($Resource)/"
        }
        Write-Verbose $BaseUrl
        $FinalResults = @()
    }
	process{
		try{
            $Params = @{
                "Uri"       = $BaseUrl
                "Method"    = $Method
                "Headers"   = $Headers
                "ContentType" = "application/json"
            }
            Write-Verbose "Data: $Data"
            if($Data){ $Params.Add("Body",$Data) }

            Write-Verbose ($Params | Out-String)
            $Results = Invoke-RestMethod @Params
            Write-Verbose "Initial Results: $Results"
            $FinalResults += $Results
            $i = 0

            while($Results.objects.count -eq $Limit){
                $i++
                Write-Verbose "Run $i  $($Results.meta.next)"
                $BaseUrl = "https://$($Server)$($Results.meta.next)"
                Write-Verbose "New Url: $BaseUrl"
                $Params = @{
                    "Uri"       = $BaseUrl
                    "Method"    = $Method
                    "Headers"   = $Headers
                }
                if($Data){ $Params.Add("Body",$Data) }
                $Results = Invoke-RestMethod @Params
                $FinalResults += $Results
            }

            Write-Verbose "Final Meta: $($FinalResults.meta)"
            Write-Output $FinalResults
        }
		catch{
			#$ErrorMessage = $_.Exception.Message
			$FailedItem = $_.Exception.ItemName
			
			Write-Output "$FailedItem"# - $ErrorMessage"
			Return $False
		}
		finally{}
	}
	end{}
}