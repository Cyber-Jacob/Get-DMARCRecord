# Get-DMARCRecord
This is a Powershell function to fetch DMARC records. DMARC is becoming a de-facto requirement for system admins that want their applications, organizations, or environments to send email. Since DMARC is becoming a requirement for mail delivery, this tool will fetch DMARC records as specified by RFC7489 (https://datatracker.ietf.org/doc/html/rfc7489). You can use this to confirm if you have successfully placed your record on the right subdomain. 


## Usage
This tool does **not** validate that record; instead this tool leaved the records you receive as a powershell object, accessible via the properties of the Microsoft.DnsClient.Commands.DnsRecord object. The ones you can use will be something like this:
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
It may ultimately be ideal to change this to be the default behavior-- specifically so this tool can be used to generate audit information by using the **-DisplayErrors, -ListSuccessfulDomains, -ListUnsuccessfulDomains, and -ShowRecords** parameters. Please let me know or feel free to fork.

If auditing a large number of domains you will likely want to want to use the **-DisplayErrors** parameter, this will give you helpful information about why the domains you are checking are failing, some may have no DMARC record, while others may have incorrect TXT records or other kinds of records hosted on the same subdomain.

