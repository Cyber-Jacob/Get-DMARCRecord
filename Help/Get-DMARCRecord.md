## Usage
This tool does **not** validate that record as p=none, p=reject, or p=quarantine; instead this tool looks for technically valid DMARC records according to RFC7489(https://datatracker.ietf.org/doc/html/rfc7489) and leaves the records you receive as a powershell object, accessible via the properties of the Microsoft.DnsClient.Commands.DnsRecord object. 

Get-DMARCRecord can fetch DMARC record(s) for a singular domain passed to it, a powershell variable that contains an array of domains, or a file path. Get-DMARCRecord expects domains only.

This tool is intended to be used for work in pipelines, or to audit one or many domains for DMARC records. As noted above, DMARC records can be audited and validated with further Powershell scripting. Get-DMARCRecord can be used as an auditing tool or simply help reduce the amount of typing you do, and reduce screen-/log-space so as to not type long nslookup or resolve-dnsname queries.

## Simple Command-Line Auditing

If you are a powershell admin, there is a chance you spend a lot of time behind a terminal and simply want to audit a set of domains at a glance and scroll through the results. The -CountRecords parameter is a useful parameter that will sum domains that do not contain valid dmarc records, and sum domains that do have valid dmarc records. It also displays a count to ensure you are feeding Get-DMARCRecord the number of records you are expecting to parse. 
Absolute paths, relative paths, variables containing arrays, and in-line lists are all accepted as input for lists of domains.

```
Get-DMARCRecord top100domains.txt -CountRecords
```
## Pipeline Operation

When working with a large number of domains, you may want to answer some basic questions about the domains you are auditing. For example: How many of these domains have a valid DMARC record at all? How many of these domains have the correct reporting address? Do any of these domains have a DMARC policy of reject? 
**Questions abound.** *But fear not!*
You can use common Powershell operators such as pipes, ForEach loops, output redirection operators, dot-notation, and more to control-- and enumerate-- the output of DMARC records you receive.

```
<#
Only output records set to a DMARC policy of reject
#>
Get-DMARCRecord $domainlist | Where-Object {$_.Strings -match "p=reject"} 

<#
Redirect successful queries to the domains with dmarc text file, and redirect errors to domains without dmarc text file. 
#>
Get-DmarcRecord 1> Domains_with_DMARC_records.txt 2>Domains_without_DMARC_records.txt 
```

There are many reasons to use Get-DMARCRecord, but I will personally recommend this Powershell cmdlet for saving the the time of having to write out repetetive Resolve-DNSName, NSLookup, or Dig queries-- even with for-loops. 

## Errors
In Get-DMARCRecord, any domain that doesn't evaluate as a technically correct DMARC record according to RFC 7489 is written to standard error stream, and as such can be redirected in Powershell with the 2 operator.
```
Get-DMARCRecord .\top100domains.txt 2>$null

Get-DMARCRecord .\top100domains.txt 2>domainswithoutDMARC.txt
```