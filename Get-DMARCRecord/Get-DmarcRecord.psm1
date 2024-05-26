function Get-DmarcRecord {
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
        [switch]$ShowRecord,

        [Parameter(
            Mandatory=$false)]
        [switch]$ListUnsuccessfulDomains,

        [Parameter(
            Mandatory=$false)]
        [switch]$ListSuccessfulDomains,

        [Parameter(
            Mandatory=$false)]
        [switch]$SuppressExplanation
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

        if (Test-Path $Name -PathType Leaf) {
            $Name = Get-Content -Path $Name
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
                if ($query.Name -match "_dmarc." -and $query.Strings -match "v=DMARC1") {
                    $successful += 1
                    $masterrecord += $query
                    write-output $query
                    $successful_domains += $domain
                }
                else {
                    <#add the query to the failed section, count it as an error, and log the error if there is a text record but it isn't a technically valid DMARC record.#>
                    $failures += 1
                    $errors += [PSCustomObject]@{
                        Domain = $domain
                        Message = "None-DMARC record found for $domain"
                    }
                    $unsuccessful_domains += $domain
                    Write-Error -Message "None-DMARC record found for $domain"
                    
                }
            }

            catch {
                <#If a terminating exception happens, count it as an error and log the error. Resolve-DNSName terminates in an error when a domain or subdomain that is queried doesn't exist. This will happen if there is NO published DMARC record.#>
                $failures += 1
                $errors += [PSCustomObject]@{
                    Domain = $domain
                    Message = $_.Exception.Message
                }    
                $unsuccessful_domains += $domain
                Write-Error -Message "Error: $_"
            }
        }
    }

    End {
        $total_records = $failures + $successful
        if ($SuppressExplanation -ne $true) {
            Write-Output "$total_records domain(s) processed."
            Write-Output "$successful DMARC record(s) found."
            Write-Output "$failures DMARC record(s) not found."
            Write-Output "See successful domains with -ListSuccessfulDomains, see unsuccessful domains with -ListUnsuccessfulDomains, get error information with -DisplayErrors, or suppress this explanation for pipeline usage with -SuppressExplanation."
        }

        if ($PSBoundParameters.Containskey("DisplayErrors")){
            Write-Output "===================="
            Write-Output "Errors are: `n"
            $errors | ForEach-Object {Write-Output $_}
        }

        if ($PSBoundParameters.ContainsKey("ShowRecords")){
            Write-Output "===================="
            Write-Output "DMARC records: `n"
            $masterrecord | ForEach-Object {Write-Output $_}
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