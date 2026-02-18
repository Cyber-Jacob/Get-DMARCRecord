<#
.HelpInfoURI 'https://github.com/Cyber-Jacob/Get-DMARCRecord/blob/main/Help/Get-DMARCRecord.md'
#>
function Invoke-DnsQuery {
    <#
    .SYNOPSIS
    Cross-platform DNS TXT lookup. Uses Resolve-DnsName on Windows, dig everywhere else.
    Returns a list of objects with Name, Type, and Strings properties.
    #>
    param (
        [Parameter(Mandatory=$true)]
        [string]$QueryName,

        [Parameter(Mandatory=$false)]
        [string]$Server
    )

    if ($IsWindows -or $env:OS -match 'Windows') {
        # Windows: use Resolve-DnsName
        $splat = @{
            'Name' = $QueryName
            'Type' = 'TXT'
            'ErrorAction' = 'Stop'
        }
        if ($Server) { $splat['Server'] = $Server }
        return (Resolve-DnsName @splat)
    }
    else {
        # Linux/macOS: use dig
        $digArgs = @('TXT', '+short', $QueryName)
        if ($Server) {
            $serverArg = '@' + $Server
            $digArgs += $serverArg
        }

        $raw = & dig @digArgs 2>&1
        if ($LASTEXITCODE -ne 0 -or -not $raw) {
            throw "dig: no record found for $QueryName"
        }

        # dig +short returns quoted strings like: "v=DMARC1; p=reject; ..."
        # Multiple lines = multiple TXT records. Strip outer quotes and return.
        $strings = @($raw | ForEach-Object { $_.Trim('"') })

        return [PSCustomObject]@{
            Name    = $QueryName
            Type    = 'TXT'
            Strings = $strings
        }
    }
}

function Get-DMARCRecord {
    param (
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            HelpMessage="Enter a list of domains. Can be a singular domain, a path, or a PS variable containing a list of domains."
            )]
        [Alias("Domains","List")]
        $Name,

        [Parameter(
            Mandatory=$false)]
        [string]$Server,

        [Parameter(
            Mandatory=$false)]
        [switch]$DisplayErrors,

        [Parameter(
            Mandatory=$false)]
        [switch]$ListUnsuccessfulDomains,

        [Parameter(
            Mandatory=$false)]
        [switch]$ListSuccessfulDomains,

        [Parameter(
            Mandatory=$false)]
        [switch]$CountRecords
        )

    begin {

        <#Initialize counting variables and processing arrays#>
        $successful = 0
        $failures = 0
        $masterrecord = @()
        $errors = @()
        $unsuccessful_domains = @()
        $successful_domains = @()

        if (-not ($Name -is [array]) -and ($Name -like "*\*" -or $Name -like "*/*")){
            #This block targets potential file paths versus a single domain or set of domains.
            if (Test-Path $Name -PathType Leaf) {
                $Name = Get-Content -Path $Name
            }
            else {
                Write-Error "Path '$Name' does not exist."
            }
        }
    }

    process {

        foreach ($domain in $Name) {
            $queryName = "_dmarc.$domain"

            try {
                <#Query statement to check DMARC records.#>
                $queryParams = @{ 'QueryName' = $queryName }
                if ($PSBoundParameters.ContainsKey('Server')) {
                    $queryParams['Server'] = $Server
                }
                $query = Invoke-DnsQuery @queryParams

                <#If the query we are returned contains _dmarc. as part of its' subdomain and a text record matching "V=DMARC1", then we
                treat it as valid and successful#>
                if ($query.Name -match "_dmarc." -and $query.Type -match "TXT" -and $query.Strings -match "v=DMARC1") {
                    $successful += 1
                    $masterrecord += $query
                    Write-Output $query
                    $successful_domains += $domain
                }

                elseif ($query.Name -notcontains "_dmarc." -or $query.Type -notcontains "TXT") {
                    <#No DMARC record; DNS may reply with SOA or other types.#>
                    $failures += 1
                    $errors += [PSCustomObject]@{
                        Domain = $domain
                        Message = "_dmarc.$domain : No DMARC record found for $domain"
                    }
                    $unsuccessful_domains += $domain
                    Write-Error -Message "_dmarc.$domain : No DMARC record found for $domain"
                }

                else {
                    <#TXT record exists but isn't a valid DMARC record.#>
                    $failures += 1
                    $errors += [PSCustomObject]@{
                        Domain = $domain
                        Message = "_dmarc.$domain : None-DMARC record found for $domain"
                    }
                    $unsuccessful_domains += $domain
                    Write-Error -Message "_dmarc.$domain : None-DMARC record found for $domain"
                }
            }

            catch {
                $failures += 1
                $errors += [PSCustomObject]@{
                    Domain = $domain
                    Message = $_.Exception.Message
                }
                $unsuccessful_domains += $domain
                Write-Error -Message "$_"
            }
        }
    }

    End {
        $total_records = $failures + $successful
        if ($PSBoundParameters.ContainsKey("CountRecords")) {
            Write-Output "$total_records domain(s) processed."
            Write-Output "$successful DMARC record(s) found."
            Write-Output "$failures DMARC record(s) not found."
            Write-Output "See successful domains with -ListSuccessfulDomains, see unsuccessful domains with -ListUnsuccessfulDomains, get error information with -DisplayErrors, suppress this explanation by omitting the -CountRecords option."
        }

        if ($PSBoundParameters.Containskey("DisplayErrors")){
            Write-Output "===================="
            Write-Output "Errors are: `n"
            $errors | ForEach-Object {Write-Output $_}
        }

        if ($PSBoundParameters.ContainsKey("ListUnsuccessfulDomains")){
            Write-Output "===================="
            Write-Output "Domains without DMARC records: `n"
            $unsuccessful_domains | ForEach-Object {Write-Output $_}
        }

        if ($PSBoundParameters.Containskey("ListSuccessfulDomains")) {
            Write-Output "===================="
            Write-Output "Domains with DMARC records: `n "
            $successful_domains | ForEach-Object {Write-Output $_}
        }
    }

}
Export-ModuleMember -Function Get-DMARCRecord
