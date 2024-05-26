## Usage
This tool does **not** validate that record as p=none, p=reject, or p=quarantine; instead this tool looks for technically valid DMARC records according to RFC7489(https://datatracker.ietf.org/doc/html/rfc7489) and leaves the records you receive as a powershell object, accessible via the properties of the Microsoft.DnsClient.Commands.DnsRecord object. The ones you can use will be something like this:
```
(Get-DMARCRecord dmarc.org).Strings
Get-DMARCRecord $domainlist | Where-Object {$_.Strings -match "v=DMARC1;"}
(Get-DMARCRecord .\domains.txt -SuppressExplanation).Strings | Where-Object {$_ -match "p=none" | -or $_ -match "p=quarantine"}
```

Currently, Get-DMARCRecord can fetch DMARC record(s) for a singular domain passed to it, a powershell variable that contains a list or array of domains, or a file path. Get-DMARCRecord expects domains only.

This tool is intended to be used for work in pipelines, or to audit one or many domains for DMARC records. As noted above, DMARC records can be audited and validated with further Powershell scripting. We may look to add validation as parameters to Get-DMARCRecord, however the main priority is to keep the tool useful and extensible so it can be used as an auditing tool or simple reduce screen- and log- so as to not type long nslookup or resolve-dnsname queries.

As of May 24, 2024 Get-DMARCRecord outputs an explanation of the number of domains processed, the amount of domains that have valid DMARC records, and the amount of domains that do not have valid DMARC records.
This can be suppressed so that only DNS Request objects are returned:

```
Get-DMARCRecord dmarc.org -SuppressExplanation
```
