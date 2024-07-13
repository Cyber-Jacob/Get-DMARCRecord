# Get-DMARCRecord

![img-GIdF6EAXze9clRgF3xn9ucy9](https://github.com/Cyber-Jacob/Get-DMARCRecord/assets/88467147/e86ea27a-6887-4c7d-b138-4e8d6ceb8507)

This is a Powershell cmdlet to fetch DMARC records. DMARC is becoming a de-facto requirement for system admins that want their applications, organizations, or environments to send email. Since DMARC is becoming a requirement for mail delivery, this tool will fetch DMARC records as specified by RFC7489 (https://datatracker.ietf.org/doc/html/rfc7489). You can use this to confirm if you have successfully placed your record on the right subdomain. 


## Usage
This tool does **not** validate that record as p=none, p=reject, or p=quarantine; instead this tool looks for technically valid DMARC records according to RFC7489(https://datatracker.ietf.org/doc/html/rfc7489) and leaves the records you receive as a powershell object, accessible via the properties of the Microsoft.DnsClient.Commands.DnsRecord object. The output of Get-DMARCRecord is intended to be standardized to return the DMARC record-- any DMARC record-- if one is present. From here, common powershell operators or expressions can be used to evaluate that record.

### **Get-DMARC Record usage and further evaluation**

```
Get-DMARCRecord topdomains.txt
(Get-DMARCRecord dmarc.org).Strings
Get-DMARCRecord $domainlist | Where-Object {$_.Strings -match "RUA@mycompany.com"}
(Get-DMARCRecord .\domains.txt).Strings | Where-Object {$_ -match "p=none" -or $_ -match "p=quarantine"}
Get-Content topdomains.txt | Get-DMARCRecord -CountRecords
```

Currently, Get-DMARCRecord can fetch DMARC record(s) for a singular domain passed to it, a powershell variable that contains a list or array of domains, pipeline or a file path. Get-DMARCRecord expects domains only.

This tool is intended to be used for work in pipelines, or to audit one or many domains for DMARC records. As noted above, DMARC records can be audited and validated with further Powershell scripting. We may look to add validation as parameters to Get-DMARCRecord, however the main priority is to keep the tool useful and extensible so it can be used as an auditing tool or simply reduce screen-space and log-space so as to not type long nslookup or resolve-dnsname queries. Get-DMARC Record can be used in a For-Loop, or as the For-Loop depending on how you input the data.

If auditing a large number of domains you will likely want to want to use the **-DisplayErrors** parameter, or one of the **-List** parameters this will give you helpful information about why the domains you are checking are failing, some may have no DMARC record, while others may have incorrect TXT records or other kinds of records hosted on the same subdomain.
