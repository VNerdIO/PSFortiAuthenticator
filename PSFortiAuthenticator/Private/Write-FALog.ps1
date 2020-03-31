<#
    .SYNOPSIS
    Generic function to write logs

    .DESCRIPTION
    Generic private function to write logs

    .EXAMPLE
    Write-Log -Log "D:\Logs\FortiAuthenticator\fa.log" -Message "Well done"

    .EXAMPLE
    $global:FALogFile = "D:\Logs\FortiAuthenticator\fa.log"

    Write-Log -Message "Well that didn't work" -Level "Error"

    .PARAMETER Log
    This should be a full path to a .log file. The file will be created with a -$DATE.log format.
    This script will also delete .log files older than $Cleanup (default 7 days) in that directory.
    You can set the variable $global:FALogFile and not have to set it everywhere you use this function.

    .PARAMETER Message
    Message you want to send to the log file

    .PARAMETER Level
    WARN/ERROR are prepended to the message. If no level is set, Info is assumed.

    .PARAMETER Cleanup
    Delete .log files older than 7 days (default) in the directory that $Log is in (e.g. D:\Logs\FA\fa.log will delete older log files in D:\Logs\FA)

    .OUTPUTS
    PSCustomObject with meta (Metadata) and objects (the actual objects)
#>
Function Write-FALog{
	[CmdletBinding()]
	Param([Parameter(Mandatory=$false)]
          [string]
		  $Log = $global:FALogFile,
          [Parameter(Mandatory=$true)]
          [string]
		  $Message,
          [Parameter(Mandatory=$false)]
          [int]
		  $Cleanup = 7,
          [string]
		  [Parameter(Mandatory=$false)]
		  [ValidateSet("Info","Warn","Error")]
          $Level)
	
	begin{
        # Set some sensible defaults
        if(!$Log){ Throw 'You must specify a log file or set $global:FALogFile somewhere' }
        if(!$Level){ $Level = "Info" }
        $Today = Get-Date -Format "yyyyMMdd"
        $Log = $Log -replace "[.]log","-$($Today).log"
        $LogDir = Split-Path $Log

        # Cleanup LogDir
        if($Cleanup -gt 0){ $Cleanup = $Cleanup * -1 }
        $CleanupDays = Get-Date(Get-Date).AddDays($Cleanup)
        Get-ChildItem $LogDir -Filter "*.log" | Where-Object { $_.LastWriteTime -lt $CleanupDays } | Remove-Item

        # Create the log file if it doesn't already exist
        if (!(Test-Path $Log)) { 
            Write-Verbose "Creating $Log." 
            $NewLogFile = New-Item $Log -Force -ItemType File 
        }
    }
	process{
		try{
            switch ($Level){
                "Info"{ $Append = "" }
                "Warn"{ $Append = "WARN: " }
                "Error"{ $Append = "ERROR: "}
            }
            $Message = "[$(Get-Date -Format s)] $($Append)$Message"
            $Message | Out-File -FilePath $Log -Append
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