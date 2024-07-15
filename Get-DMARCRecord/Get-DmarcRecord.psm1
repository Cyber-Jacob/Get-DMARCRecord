<#
.HelpInfoURI 'https://github.com/Cyber-Jacob/Get-DMARCRecord/blob/main/Help/Get-DMARCRecord.md'
#>
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

        $splat_parameters = @{
            'Type' = 'TXT'
            'ErrorAction' = 'Stop'
        }

        if ($PSBoundParameters.ContainsKey('Server')) {
            $splat_parameters['Server'] = $Server
        }

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
            <#Set the domain name for the Resolve-DnsName query string by editing splat_parameters. Having this here allows us to parse domains from the position 0 Name parameter as singular items, or as many can fit into a variable or file.#>
            $splat_parameters['Name'] = "_dmarc.$domain"

            try {
                <#Query statement to check DMARC records.#>
                $query = resolve-dnsname @splat_parameters

                <#If the query we are returned contains _dmarc. as part of its' subdomain and a text record matching "V=DMARC1", then we
                treat it as valid and successful
                Write the query to show the user what is happening and let them know what they see in terms of valid records.#>
                if ($query.Name -match "_dmarc." -and $query.Type -match "TXT" -and $query.Strings -match "v=DMARC1") {
                    $successful += 1
                    $masterrecord += $query
                    write-output $query
                    $successful_domains += $domain
                }

                elseif ($query.Name -notcontains "_dmarc." -or $query.Type -notcontains "TXT") {
                    <#Determine if there is no DMARC record; in some cases DNS servers will reply with different record types like an SOA record. We will count this as NO DMARC found instead of a none-dmarc record.#>
                    $failures += 1
                    $errors += [PSCustomObject]@{
                        Domain = $domain
                        Message = "_dmarc.$domain : No DMARC record found for $domain"
                    }
                    $unsuccessful_domains += $domain
                    Write-Error -Message "_dmarc.$domain : No DMARC record found for $domain"
                }

                else {
                    <#add the query to the failed section, count it as an error, and log the error if there is a text record but it isn't a technically valid DMARC record.#>
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
                <#If a terminating exception happens, count it as an error and log the error. Since we are using -erroraction stop, Resolve-DNSName terminates in an error when a domain that is queried doesn't exist. This will happen if there is NO record of any type published at _dmarc.$domain. The error handling above addresses invalid TXT records placed on _dmarc.$domain.#>
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