
 aws route53 get-hosted-zone \
 --id $(aws route53 list-hosted-zones-by-name --dns-name c.cloudtuple.org --query "HostedZones[?Name=='c.cloudtuple.org.'].Id" \
 --output text) \
 --query "VPCs[*].VPCId" \
 --output text
