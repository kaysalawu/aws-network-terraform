
# Common

#----------------------------
locals {
  username = "ubuntu"
  password = "Password123"
  vmsize   = "t3.micro"
  psk      = "changeme"

  default_region = "eu-west-1"
  region1        = "eu-west-1"
  region2        = "us-east-2"
  region1_code   = "eu"
  region2_code   = "us"

  bgp_apipa_range1 = "169.254.21.0/30"
  bgp_apipa_range2 = "169.254.21.4/30"
  bgp_apipa_range3 = "169.254.21.8/30"
  bgp_apipa_range4 = "169.254.21.12/30"
  bgp_apipa_range5 = "169.254.21.16/30"
  bgp_apipa_range6 = "169.254.21.20/30"
  bgp_apipa_range7 = "169.254.21.24/30"
  bgp_apipa_range8 = "169.254.21.28/30"

  csp_range1 = "172.16.0.0/30"
  csp_range2 = "172.16.0.4/30"
  csp_range3 = "172.16.0.8/30"
  csp_range4 = "172.16.0.12/30"
  csp_range5 = "172.16.0.16/30"
  csp_range6 = "172.16.0.20/30"
  csp_range7 = "172.16.0.24/30"
  csp_range8 = "172.16.0.28/30"

  csp_range1_v6 = "2001:db8:1::/126"
  csp_range2_v6 = "2001:db8:1:1::/126"
  csp_range3_v6 = "2001:db8:1:2::/126"
  csp_range4_v6 = "2001:db8:1:3::/126"
  csp_range5_v6 = "2001:db8:1:4::/126"
  csp_range6_v6 = "2001:db8:1:5::/126"
  csp_range7_v6 = "2001:db8:1:6::/126"
  csp_range8_v6 = "2001:db8:1:7::/126"

  vti_range0 = "10.10.10.0/30"
  vti_range1 = "10.10.10.4/30"
  vti_range2 = "10.10.10.8/30"
  vti_range3 = "10.10.10.12/30"
  vti_range4 = "10.10.10.16/30"
  vti_range5 = "10.10.10.20/30"
  vti_range6 = "10.10.10.24/30"
  vti_range7 = "10.10.10.28/30"

  domain_name      = "cloudtuple.org"
  onprem_domain    = local.domain_name
  cloud_dns_zone   = "c.${local.domain_name}"
  region1_dns_zone = "${local.region1_code}.${local.cloud_dns_zone}"
  region2_dns_zone = "${local.region2_code}.${local.cloud_dns_zone}"
  amazon_dns_ipv4  = "169.254.169.253"
  amazon_dns_ipv6  = "fd00:ec2::253"
  internet_proxy   = "8.8.8.8/32" # test only

  private_prefixes_ipv4 = [
    "10.0.0.0/8",
    # "172.16.0.0/12",
    # "192.168.0.0/16",
    # "100.64.0.0/10",
  ]
  private_prefixes_ipv6 = [
    "2000::/3",
    "fd00::/8",
  ]

  aws_asn          = 12076
  aws_internal_asn = 65515
  megaport_asn     = 64512
}

# tgw1
#----------------------------

locals {
  tgw1_prefix            = var.prefix == "" ? "tgw1-" : join("-", [var.prefix, "tgw1-"])
  tgw1_region            = local.region1
  tgw1_bgp_asn           = "65011"
  tgw1_address_prefixes  = ["192.168.11.0/24", ]
  tgw1_vpngw_bgp_apipa_0 = cidrhost(local.bgp_apipa_range1, 1)
  tgw1_vpngw_bgp_apipa_1 = cidrhost(local.bgp_apipa_range2, 1)
}

# tgw2
#----------------------------

locals {
  tgw2_prefix            = var.prefix == "" ? "tgw2-" : join("-", [var.prefix, "tgw2-"])
  tgw2_region            = local.region2
  tgw2_bgp_asn           = "65022"
  tgw2_address_prefixes  = ["192.168.22.0/24", ]
  tgw2_vpngw_bgp_apipa_0 = cidrhost(local.bgp_apipa_range3, 1)
  tgw2_vpngw_bgp_apipa_1 = cidrhost(local.bgp_apipa_range4, 1)
}

# hub1
#----------------------------

locals {
  hub1_prefix        = var.prefix == "" ? "hub1-" : join("-", [var.prefix, "hub1-"])
  hub1_region        = local.region1
  hub1_cidr          = ["10.11.0.0/16", ]
  hub1_ipv6_cidr     = ["2000:abc:11::/56", ]
  hub1_bgp_community = "12076:20011"
  hub1_dns_zone      = local.region1_dns_zone
  hub1_subnets = {
    ("MainSubnetA")        = { cidr = "10.11.0.0/24", ipv6_cidr = "2000:abc:11:0::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("MainSubnetB")        = { cidr = "10.11.1.0/24", ipv6_cidr = "2000:abc:11:1::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("UntrustSubnetA")     = { cidr = "10.11.2.0/24", ipv6_cidr = "2000:abc:11:2::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("UntrustSubnetB")     = { cidr = "10.11.3.0/24", ipv6_cidr = "2000:abc:11:3::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("TrustSubnetA")       = { cidr = "10.11.4.0/24", ipv6_cidr = "2000:abc:11:4::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("TrustSubnetB")       = { cidr = "10.11.5.0/24", ipv6_cidr = "2000:abc:11:5::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ManagementSubnetA")  = { cidr = "10.11.6.0/24", ipv6_cidr = "2000:abc:11:6::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("ManagementSubnetB")  = { cidr = "10.11.7.0/24", ipv6_cidr = "2000:abc:11:7::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("DnsInboundSubnetA")  = { cidr = "10.11.8.0/24", ipv6_cidr = "2000:abc:11:8::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("DnsInboundSubnetB")  = { cidr = "10.11.9.0/24", ipv6_cidr = "2000:abc:11:9::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("DnsOutboundSubnetA") = { cidr = "10.11.10.0/24", ipv6_cidr = "2000:abc:11:10::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("DnsOutboundSubnetB") = { cidr = "10.11.11.0/24", ipv6_cidr = "2000:abc:11:11::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ExternalALBSubnetA") = { cidr = "10.11.12.0/24", ipv6_cidr = "2000:abc:11:12::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("ExternalALBSubnetB") = { cidr = "10.11.13.0/24", ipv6_cidr = "2000:abc:11:13::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("InternalALBSubnetA") = { cidr = "10.11.14.0/24", ipv6_cidr = "2000:abc:11:14::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("InternalALBSubnetB") = { cidr = "10.11.15.0/24", ipv6_cidr = "2000:abc:11:15::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ExternalNLBSubnetA") = { cidr = "10.11.16.0/24", ipv6_cidr = "2000:abc:11:16::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("ExternalNLBSubnetB") = { cidr = "10.11.17.0/24", ipv6_cidr = "2000:abc:11:17::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("InternalNLBSubnetA") = { cidr = "10.11.18.0/24", ipv6_cidr = "2000:abc:11:18::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("InternalNLBSubnetB") = { cidr = "10.11.19.0/24", ipv6_cidr = "2000:abc:11:19::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("EndpointSubnetA")    = { cidr = "10.11.20.0/24", ipv6_cidr = "2000:abc:11:20::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("EndpointSubnetB")    = { cidr = "10.11.21.0/24", ipv6_cidr = "2000:abc:11:21::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("AksSubnetA")         = { cidr = "10.11.80.0/20", ipv6_cidr = "2000:abc:11:80::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("AksSubnetB")         = { cidr = "10.11.96.0/20", ipv6_cidr = "2000:abc:11:96::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
  }
  hub1_default_gw_main          = cidrhost(local.hub1_subnets["MainSubnetA"].cidr, 1)
  hub1_default_gw_untrust       = cidrhost(local.hub1_subnets["UntrustSubnetA"].cidr, 1)
  hub1_default_gw_trust         = cidrhost(local.hub1_subnets["TrustSubnetA"].cidr, 1)
  hub1_vm_addr                  = cidrhost(local.hub1_subnets["MainSubnetA"].cidr, 5)
  hub1_nva_trust_addr           = cidrhost(local.hub1_subnets["TrustSubnetA"].cidr, 4)
  hub1_nva_untrust_addr         = cidrhost(local.hub1_subnets["UntrustSubnetA"].cidr, 4)
  hub1_bastion_addr             = cidrhost(local.hub1_subnets["UntrustSubnetA"].cidr, 55)
  hub1_nva_int_nlb_trust_addr   = cidrhost(local.hub1_subnets["TrustSubnetA"].cidr, 99)
  hub1_nva_int_nlb_untrust_addr = cidrhost(local.hub1_subnets["UntrustSubnetA"].cidr, 99)

  hub1_int_nlb_addr_a = cidrhost(local.hub1_subnets["InternalNLBSubnetA"].cidr, 99)
  hub1_int_nlb_addr_b = cidrhost(local.hub1_subnets["InternalNLBSubnetB"].cidr, 99)
  hub1_int_alb_addr_a = cidrhost(local.hub1_subnets["InternalALBSubnetA"].cidr, 99)
  hub1_int_alb_addr_b = cidrhost(local.hub1_subnets["InternalALBSubnetB"].cidr, 99)
  hub1_ext_nlb_addr_a = cidrhost(local.hub1_subnets["ExternalNLBSubnetA"].cidr, 99)
  hub1_ext_nlb_addr_b = cidrhost(local.hub1_subnets["ExternalNLBSubnetB"].cidr, 99)
  hub1_ext_alb_addr_a = cidrhost(local.hub1_subnets["ExternalALBSubnetA"].cidr, 99)
  hub1_ext_alb_addr_b = cidrhost(local.hub1_subnets["ExternalALBSubnetB"].cidr, 99)

  hub1_vm_addr_v6                  = cidrhost(local.hub1_subnets["MainSubnetA"].ipv6_cidr, 5)
  hub1_nva_trust_addr_v6           = cidrhost(local.hub1_subnets["TrustSubnetA"].ipv6_cidr, 4)
  hub1_nva_untrust_addr_v6         = cidrhost(local.hub1_subnets["UntrustSubnetA"].ipv6_cidr, 4)
  hub1_nva_int_nlb_trust_addr_v6   = cidrhost(local.hub1_subnets["TrustSubnetA"].ipv6_cidr, 153)
  hub1_nva_int_nlb_untrust_addr_v6 = cidrhost(local.hub1_subnets["UntrustSubnetA"].ipv6_cidr, 153)

  hub1_dns_in_addr1     = cidrhost(local.hub1_subnets["DnsInboundSubnetA"].cidr, 4)
  hub1_dns_in_addr2     = cidrhost(local.hub1_subnets["DnsInboundSubnetB"].cidr, 4)
  hub1_dns_out_addr1    = cidrhost(local.hub1_subnets["DnsOutboundSubnetA"].cidr, 4)
  hub1_dns_out_addr2    = cidrhost(local.hub1_subnets["DnsOutboundSubnetB"].cidr, 4)
  hub1_nva_loopback0    = "10.11.11.11"
  hub1_nva_tun_range0   = "10.11.50.0/30"
  hub1_nva_tun_range1   = "10.11.51.4/30"
  hub1_vm_hostname      = "hub1Vm"
  hub1_int_nlb_hostname = "hub1-nlb"
  hub1_spoke1_pep_host  = "spoke1pls"
  hub1_spoke2_pep_host  = "spoke2pls"
  hub1_spoke3_pep_host  = "spoke3pls"
  hub1_vm_fqdn          = "${local.hub1_vm_hostname}.${local.hub1_dns_zone}"
  hub1_spoke1_pep_fqdn  = "${local.hub1_spoke1_pep_host}.${local.hub1_dns_zone}"
  hub1_spoke2_pep_fqdn  = "${local.hub1_spoke2_pep_host}.${local.hub1_dns_zone}"
  hub1_spoke3_pep_fqdn  = "${local.hub1_spoke3_pep_host}.${local.hub1_dns_zone}"
}

# hub2
#----------------------------

locals {
  hub2_prefix        = var.prefix == "" ? "hub2-" : join("-", [var.prefix, "hub2-"])
  hub2_region        = local.region2
  hub2_cidr          = ["10.22.0.0/16", ]
  hub2_ipv6_cidr     = ["2000:abc:22::/56", ]
  hub2_bgp_community = "12076:20022"
  hub2_dns_zone      = local.region2_dns_zone
  hub2_subnets = {
    ("MainSubnetA")        = { cidr = "10.22.0.0/24", ipv6_cidr = "2000:abc:22:0::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("MainSubnetB")        = { cidr = "10.22.1.0/24", ipv6_cidr = "2000:abc:22:1::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("UntrustSubnetA")     = { cidr = "10.22.2.0/24", ipv6_cidr = "2000:abc:22:2::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("UntrustSubnetB")     = { cidr = "10.22.3.0/24", ipv6_cidr = "2000:abc:22:3::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("TrustSubnetA")       = { cidr = "10.22.4.0/24", ipv6_cidr = "2000:abc:22:4::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("TrustSubnetB")       = { cidr = "10.22.5.0/24", ipv6_cidr = "2000:abc:22:5::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ManagementSubnetA")  = { cidr = "10.22.6.0/24", ipv6_cidr = "2000:abc:22:6::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("ManagementSubnetB")  = { cidr = "10.22.7.0/24", ipv6_cidr = "2000:abc:22:7::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("DnsInboundSubnetA")  = { cidr = "10.22.8.0/24", ipv6_cidr = "2000:abc:22:8::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("DnsInboundSubnetB")  = { cidr = "10.22.9.0/24", ipv6_cidr = "2000:abc:22:9::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("DnsOutboundSubnetA") = { cidr = "10.22.10.0/24", ipv6_cidr = "2000:abc:22:10::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("DnsOutboundSubnetB") = { cidr = "10.22.11.0/24", ipv6_cidr = "2000:abc:22:11::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ExternalALBSubnetA") = { cidr = "10.22.12.0/24", ipv6_cidr = "2000:abc:22:12::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("ExternalALBSubnetB") = { cidr = "10.22.13.0/24", ipv6_cidr = "2000:abc:22:13::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("InternalALBSubnetA") = { cidr = "10.22.14.0/24", ipv6_cidr = "2000:abc:22:14::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("InternalALBSubnetB") = { cidr = "10.22.15.0/24", ipv6_cidr = "2000:abc:22:15::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ExternalNLBSubnetA") = { cidr = "10.22.16.0/24", ipv6_cidr = "2000:abc:22:16::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("ExternalNLBSubnetB") = { cidr = "10.22.17.0/24", ipv6_cidr = "2000:abc:22:17::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("InternalNLBSubnetA") = { cidr = "10.22.18.0/24", ipv6_cidr = "2000:abc:22:18::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("InternalNLBSubnetB") = { cidr = "10.22.19.0/24", ipv6_cidr = "2000:abc:22:19::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("EndpointSubnetA")    = { cidr = "10.22.20.0/24", ipv6_cidr = "2000:abc:22:20::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("EndpointSubnetB")    = { cidr = "10.22.21.0/24", ipv6_cidr = "2000:abc:22:21::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("AksSubnetA")         = { cidr = "10.22.80.0/20", ipv6_cidr = "2000:abc:22:80::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("AksSubnetB")         = { cidr = "10.22.96.0/20", ipv6_cidr = "2000:abc:22:96::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
  }
  hub2_default_gw_main          = cidrhost(local.hub2_subnets["MainSubnetA"].cidr, 1)
  hub2_default_gw_untrust       = cidrhost(local.hub2_subnets["UntrustSubnetA"].cidr, 1)
  hub2_default_gw_trust         = cidrhost(local.hub2_subnets["TrustSubnetA"].cidr, 1)
  hub2_vm_addr                  = cidrhost(local.hub2_subnets["MainSubnetA"].cidr, 5)
  hub2_nva_trust_addr           = cidrhost(local.hub2_subnets["TrustSubnetA"].cidr, 4)
  hub2_nva_untrust_addr         = cidrhost(local.hub2_subnets["UntrustSubnetA"].cidr, 4)
  hub2_bastion_addr             = cidrhost(local.hub2_subnets["UntrustSubnetA"].cidr, 55)
  hub2_nva_int_nlb_trust_addr   = cidrhost(local.hub2_subnets["TrustSubnetA"].cidr, 99)
  hub2_nva_int_nlb_untrust_addr = cidrhost(local.hub2_subnets["UntrustSubnetA"].cidr, 99)

  hub2_int_nlb_addr_a = cidrhost(local.hub2_subnets["InternalNLBSubnetA"].cidr, 99)
  hub2_int_nlb_addr_b = cidrhost(local.hub2_subnets["InternalNLBSubnetB"].cidr, 99)
  hub2_int_alb_addr_a = cidrhost(local.hub2_subnets["InternalALBSubnetA"].cidr, 99)
  hub2_int_alb_addr_b = cidrhost(local.hub2_subnets["InternalALBSubnetB"].cidr, 99)
  hub2_ext_nlb_addr_a = cidrhost(local.hub2_subnets["ExternalNLBSubnetA"].cidr, 99)
  hub2_ext_nlb_addr_b = cidrhost(local.hub2_subnets["ExternalNLBSubnetB"].cidr, 99)
  hub2_ext_alb_addr_a = cidrhost(local.hub2_subnets["ExternalALBSubnetA"].cidr, 99)
  hub2_ext_alb_addr_b = cidrhost(local.hub2_subnets["ExternalALBSubnetB"].cidr, 99)

  hub2_vm_addr_v6                  = cidrhost(local.hub2_subnets["MainSubnetA"].ipv6_cidr, 5)
  hub2_nva_trust_addr_v6           = cidrhost(local.hub2_subnets["TrustSubnetA"].ipv6_cidr, 4)
  hub2_nva_untrust_addr_v6         = cidrhost(local.hub2_subnets["UntrustSubnetA"].ipv6_cidr, 4)
  hub2_nva_int_nlb_trust_addr_v6   = cidrhost(local.hub2_subnets["TrustSubnetA"].ipv6_cidr, 153)
  hub2_nva_int_nlb_untrust_addr_v6 = cidrhost(local.hub2_subnets["UntrustSubnetA"].ipv6_cidr, 153)

  hub2_dns_in_addr1     = cidrhost(local.hub2_subnets["DnsInboundSubnetA"].cidr, 4)
  hub2_dns_in_addr2     = cidrhost(local.hub2_subnets["DnsInboundSubnetB"].cidr, 4)
  hub2_dns_out_addr1    = cidrhost(local.hub2_subnets["DnsOutboundSubnetA"].cidr, 4)
  hub2_dns_out_addr2    = cidrhost(local.hub2_subnets["DnsOutboundSubnetB"].cidr, 4)
  hub2_nva_loopback0    = "10.22.22.22"
  hub2_nva_tun_range0   = "10.22.50.0/30"
  hub2_nva_tun_range1   = "10.22.51.4/30"
  hub2_vm_hostname      = "hub2Vm"
  hub2_int_nlb_hostname = "hub2-nlb"
  hub2_spoke4_pep_host  = "spoke4pls"
  hub2_spoke5_pep_host  = "spoke5pls"
  hub2_spoke6_pep_host  = "spoke6pls"
  hub2_vm_fqdn          = "${local.hub2_vm_hostname}.${local.hub2_dns_zone}"
  hub2_spoke4_pep_fqdn  = "${local.hub2_spoke4_pep_host}.${local.hub2_dns_zone}"
  hub2_spoke5_pep_fqdn  = "${local.hub2_spoke5_pep_host}.${local.hub2_dns_zone}"
  hub2_spoke6_pep_fqdn  = "${local.hub2_spoke6_pep_host}.${local.hub2_dns_zone}"
}

# branch1
#----------------------------

locals {
  branch1_prefix        = var.prefix == "" ? "branch1-" : join("-", [var.prefix, "branch1-"])
  branch1_region        = local.region1
  branch1_cidr          = ["10.10.0.0/16", ]
  branch1_ipv6_cidr     = ["2000:abc:10::/56", ]
  branch1_bgp_community = "12076:20010"
  branch1_nva_asn       = "65001"
  branch1_dns_zone      = local.onprem_domain
  branch1_subnets = {
    ("MainSubnetA")        = { cidr = "10.10.0.0/24", ipv6_cidr = "2000:abc:10:0::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("MainSubnetB")        = { cidr = "10.10.1.0/24", ipv6_cidr = "2000:abc:10:1::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("UntrustSubnetA")     = { cidr = "10.10.2.0/24", ipv6_cidr = "2000:abc:10:2::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("UntrustSubnetB")     = { cidr = "10.10.3.0/24", ipv6_cidr = "2000:abc:10:3::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("TrustSubnetA")       = { cidr = "10.10.4.0/24", ipv6_cidr = "2000:abc:10:4::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("TrustSubnetB")       = { cidr = "10.10.5.0/24", ipv6_cidr = "2000:abc:10:5::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ManagementSubnetA")  = { cidr = "10.10.6.0/24", ipv6_cidr = "2000:abc:10:6::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("ManagementSubnetB")  = { cidr = "10.10.7.0/24", ipv6_cidr = "2000:abc:10:7::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("DnsInboundSubnetA")  = { cidr = "10.10.8.0/24", ipv6_cidr = "2000:abc:10:8::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("DnsInboundSubnetB")  = { cidr = "10.10.9.0/24", ipv6_cidr = "2000:abc:10:9::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("DnsOutboundSubnetA") = { cidr = "10.10.10.0/24", ipv6_cidr = "2000:abc:10:10::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("DnsOutboundSubnetB") = { cidr = "10.10.11.0/24", ipv6_cidr = "2000:abc:10:11::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ExternalALBSubnetA") = { cidr = "10.10.12.0/24", ipv6_cidr = "2000:abc:10:12::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("ExternalALBSubnetB") = { cidr = "10.10.13.0/24", ipv6_cidr = "2000:abc:10:13::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("InternalALBSubnetA") = { cidr = "10.10.14.0/24", ipv6_cidr = "2000:abc:10:14::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("InternalALBSubnetB") = { cidr = "10.10.15.0/24", ipv6_cidr = "2000:abc:10:15::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ExternalNLBSubnetA") = { cidr = "10.10.16.0/24", ipv6_cidr = "2000:abc:10:16::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("ExternalNLBSubnetB") = { cidr = "10.10.17.0/24", ipv6_cidr = "2000:abc:10:17::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("InternalNLBSubnetA") = { cidr = "10.10.18.0/24", ipv6_cidr = "2000:abc:10:18::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("InternalNLBSubnetB") = { cidr = "10.10.19.0/24", ipv6_cidr = "2000:abc:10:19::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("EndpointSubnetA")    = { cidr = "10.10.20.0/24", ipv6_cidr = "2000:abc:10:20::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("EndpointSubnetB")    = { cidr = "10.10.21.0/24", ipv6_cidr = "2000:abc:10:21::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("AksSubnetA")         = { cidr = "10.10.80.0/20", ipv6_cidr = "2000:abc:10:80::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("AksSubnetB")         = { cidr = "10.10.96.0/20", ipv6_cidr = "2000:abc:10:96::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
  }
  branch1_untrust_default_gw = cidrhost(local.branch1_subnets["UntrustSubnetA"].cidr, 1)
  branch1_trust_default_gw   = cidrhost(local.branch1_subnets["TrustSubnetA"].cidr, 1)
  branch1_nva_untrust_addr   = cidrhost(local.branch1_subnets["UntrustSubnetA"].cidr, 9)
  branch1_nva_trust_addr     = cidrhost(local.branch1_subnets["TrustSubnetA"].cidr, 9)
  branch1_vm_addr            = cidrhost(local.branch1_subnets["MainSubnetA"].cidr, 5)
  branch1_dns_addr           = cidrhost(local.branch1_subnets["MainSubnetA"].cidr, 6)
  branch1_bastion_addr       = cidrhost(local.branch1_subnets["UntrustSubnetA"].cidr, 55)

  branch1_nva_untrust_addr_v6 = cidrhost(local.branch1_subnets["UntrustSubnetA"].ipv6_cidr, 9)
  branch1_nva_trust_addr_v6   = cidrhost(local.branch1_subnets["TrustSubnetA"].ipv6_cidr, 9)
  branch1_vm_addr_v6          = cidrhost(local.branch1_subnets["MainSubnetA"].ipv6_cidr, 5)
  branch1_dns_addr_v6         = cidrhost(local.branch1_subnets["MainSubnetA"].ipv6_cidr, 6)

  branch1_nva_loopback0 = "192.168.10.10"
  branch1_vm_hostname   = "branch1Vm"
  branch1_nva_hostname  = "branch1Nva"
  branch1_dns_hostname  = "branch1Dns"
  branch1_vm_fqdn       = "${local.branch1_vm_hostname}.${local.onprem_domain}"
}

# branch2
#----------------------------

locals {
  branch2_prefix        = var.prefix == "" ? "branch2-" : join("-", [var.prefix, "branch2-"])
  branch2_region        = local.region1
  branch2_cidr          = ["10.20.0.0/16", ]
  branch2_ipv6_cidr     = ["2000:abc:20::/56", ]
  branch2_bgp_community = "12076:20020"
  branch2_nva_asn       = "65002"
  branch2_dns_zone      = local.onprem_domain
  branch2_subnets = {
    ("MainSubnetA")        = { cidr = "10.20.0.0/24", ipv6_cidr = "2000:abc:20:0::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("MainSubnetB")        = { cidr = "10.20.1.0/24", ipv6_cidr = "2000:abc:20:1::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("UntrustSubnetA")     = { cidr = "10.20.2.0/24", ipv6_cidr = "2000:abc:20:2::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("UntrustSubnetB")     = { cidr = "10.20.3.0/24", ipv6_cidr = "2000:abc:20:3::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("TrustSubnetA")       = { cidr = "10.20.4.0/24", ipv6_cidr = "2000:abc:20:4::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("TrustSubnetB")       = { cidr = "10.20.5.0/24", ipv6_cidr = "2000:abc:20:5::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ManagementSubnetA")  = { cidr = "10.20.6.0/24", ipv6_cidr = "2000:abc:20:6::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("ManagementSubnetB")  = { cidr = "10.20.7.0/24", ipv6_cidr = "2000:abc:20:7::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("DnsInboundSubnetA")  = { cidr = "10.20.8.0/24", ipv6_cidr = "2000:abc:20:8::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("DnsInboundSubnetB")  = { cidr = "10.20.9.0/24", ipv6_cidr = "2000:abc:20:9::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("DnsOutboundSubnetA") = { cidr = "10.20.10.0/24", ipv6_cidr = "2000:abc:20:10::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("DnsOutboundSubnetB") = { cidr = "10.20.11.0/24", ipv6_cidr = "2000:abc:20:11::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ExternalALBSubnetA") = { cidr = "10.20.12.0/24", ipv6_cidr = "2000:abc:20:12::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("ExternalALBSubnetB") = { cidr = "10.20.13.0/24", ipv6_cidr = "2000:abc:20:13::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("InternalALBSubnetA") = { cidr = "10.20.14.0/24", ipv6_cidr = "2000:abc:20:14::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("InternalALBSubnetB") = { cidr = "10.20.15.0/24", ipv6_cidr = "2000:abc:20:15::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ExternalNLBSubnetA") = { cidr = "10.20.16.0/24", ipv6_cidr = "2000:abc:20:16::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("ExternalNLBSubnetB") = { cidr = "10.20.17.0/24", ipv6_cidr = "2000:abc:20:17::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("InternalNLBSubnetA") = { cidr = "10.20.18.0/24", ipv6_cidr = "2000:abc:20:18::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("InternalNLBSubnetB") = { cidr = "10.20.19.0/24", ipv6_cidr = "2000:abc:20:19::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("EndpointSubnetA")    = { cidr = "10.20.20.0/24", ipv6_cidr = "2000:abc:20:20::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("EndpointSubnetB")    = { cidr = "10.20.21.0/24", ipv6_cidr = "2000:abc:20:21::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("AksSubnetA")         = { cidr = "10.20.80.0/20", ipv6_cidr = "2000:abc:20:80::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("AksSubnetB")         = { cidr = "10.20.96.0/20", ipv6_cidr = "2000:abc:20:96::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
  }
  branch2_untrust_default_gw = cidrhost(local.branch2_subnets["UntrustSubnetA"].cidr, 1)
  branch2_trust_default_gw   = cidrhost(local.branch2_subnets["TrustSubnetA"].cidr, 1)
  branch2_nva_untrust_addr   = cidrhost(local.branch2_subnets["UntrustSubnetA"].cidr, 9)
  branch2_nva_trust_addr     = cidrhost(local.branch2_subnets["TrustSubnetA"].cidr, 9)
  branch2_vm_addr            = cidrhost(local.branch2_subnets["MainSubnetA"].cidr, 5)
  branch2_dns_addr           = cidrhost(local.branch2_subnets["MainSubnetA"].cidr, 6)
  branch2_bastion_addr       = cidrhost(local.branch2_subnets["UntrustSubnetA"].cidr, 55)

  branch2_nva_untrust_addr_v6 = cidrhost(local.branch2_subnets["UntrustSubnetA"].ipv6_cidr, 9)
  branch2_nva_trust_addr_v6   = cidrhost(local.branch2_subnets["TrustSubnetA"].ipv6_cidr, 9)
  branch2_vm_addr_v6          = cidrhost(local.branch2_subnets["MainSubnetA"].ipv6_cidr, 5)
  branch2_dns_addr_v6         = cidrhost(local.branch2_subnets["MainSubnetA"].ipv6_cidr, 6)

  branch2_nva_loopback0 = "192.168.20.20"
  branch2_vm_hostname   = "branch2Vm"
  branch2_nva_hostname  = "branch2Nva"
  branch2_dns_hostname  = "branch2Dns"
  branch2_vm_fqdn       = "${local.branch2_vm_hostname}.${local.onprem_domain}"
}

# branch3
#----------------------------

locals {
  branch3_prefix        = var.prefix == "" ? "branch3-" : join("-", [var.prefix, "branch3-"])
  branch3_region        = local.region2
  branch3_cidr          = ["10.30.0.0/16", ]
  branch3_ipv6_cidr     = ["2000:abc:30::/56", ]
  branch3_bgp_community = "12076:20030"
  branch3_nva_asn       = "65003"
  branch3_dns_zone      = local.onprem_domain
  branch3_subnets = {
    ("MainSubnetA")        = { cidr = "10.30.0.0/24", ipv6_cidr = "2000:abc:30:0::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("MainSubnetB")        = { cidr = "10.30.1.0/24", ipv6_cidr = "2000:abc:30:1::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("UntrustSubnetA")     = { cidr = "10.30.2.0/24", ipv6_cidr = "2000:abc:30:2::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("UntrustSubnetB")     = { cidr = "10.30.3.0/24", ipv6_cidr = "2000:abc:30:3::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("TrustSubnetA")       = { cidr = "10.30.4.0/24", ipv6_cidr = "2000:abc:30:4::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("TrustSubnetB")       = { cidr = "10.30.5.0/24", ipv6_cidr = "2000:abc:30:5::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ManagementSubnetA")  = { cidr = "10.30.6.0/24", ipv6_cidr = "2000:abc:30:6::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("ManagementSubnetB")  = { cidr = "10.30.7.0/24", ipv6_cidr = "2000:abc:30:7::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("DnsInboundSubnetA")  = { cidr = "10.30.8.0/24", ipv6_cidr = "2000:abc:30:8::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("DnsInboundSubnetB")  = { cidr = "10.30.9.0/24", ipv6_cidr = "2000:abc:30:9::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("DnsOutboundSubnetA") = { cidr = "10.30.10.0/24", ipv6_cidr = "2000:abc:30:10::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("DnsOutboundSubnetB") = { cidr = "10.30.11.0/24", ipv6_cidr = "2000:abc:30:11::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ExternalALBSubnetA") = { cidr = "10.30.12.0/24", ipv6_cidr = "2000:abc:30:12::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("ExternalALBSubnetB") = { cidr = "10.30.13.0/24", ipv6_cidr = "2000:abc:30:13::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("InternalALBSubnetA") = { cidr = "10.30.14.0/24", ipv6_cidr = "2000:abc:30:14::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("InternalALBSubnetB") = { cidr = "10.30.15.0/24", ipv6_cidr = "2000:abc:30:15::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ExternalNLBSubnetA") = { cidr = "10.30.16.0/24", ipv6_cidr = "2000:abc:30:16::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("ExternalNLBSubnetB") = { cidr = "10.30.17.0/24", ipv6_cidr = "2000:abc:30:17::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("InternalNLBSubnetA") = { cidr = "10.30.18.0/24", ipv6_cidr = "2000:abc:30:18::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("InternalNLBSubnetB") = { cidr = "10.30.19.0/24", ipv6_cidr = "2000:abc:30:19::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("EndpointSubnetA")    = { cidr = "10.30.20.0/24", ipv6_cidr = "2000:abc:30:20::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("EndpointSubnetB")    = { cidr = "10.30.21.0/24", ipv6_cidr = "2000:abc:30:21::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("AksSubnetA")         = { cidr = "10.30.80.0/20", ipv6_cidr = "2000:abc:30:80::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("AksSubnetB")         = { cidr = "10.30.96.0/20", ipv6_cidr = "2000:abc:30:96::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
  }
  branch3_untrust_default_gw = cidrhost(local.branch3_subnets["UntrustSubnetA"].cidr, 1)
  branch3_trust_default_gw   = cidrhost(local.branch3_subnets["TrustSubnetA"].cidr, 1)
  branch3_nva_untrust_addr   = cidrhost(local.branch3_subnets["UntrustSubnetA"].cidr, 9)
  branch3_nva_trust_addr     = cidrhost(local.branch3_subnets["TrustSubnetA"].cidr, 9)
  branch3_vm_addr            = cidrhost(local.branch3_subnets["MainSubnetA"].cidr, 5)
  branch3_dns_addr           = cidrhost(local.branch3_subnets["MainSubnetA"].cidr, 6)
  branch3_bastion_addr       = cidrhost(local.branch3_subnets["UntrustSubnetA"].cidr, 55)

  branch3_nva_untrust_addr_v6 = cidrhost(local.branch3_subnets["UntrustSubnetA"].ipv6_cidr, 9)
  branch3_nva_trust_addr_v6   = cidrhost(local.branch3_subnets["TrustSubnetA"].ipv6_cidr, 9)
  branch3_vm_addr_v6          = cidrhost(local.branch3_subnets["MainSubnetA"].ipv6_cidr, 5)
  branch3_dns_addr_v6         = cidrhost(local.branch3_subnets["MainSubnetA"].ipv6_cidr, 6)

  branch3_nva_loopback0 = "192.168.30.30"
  branch3_vm_hostname   = "branch3Vm"
  branch3_nva_hostname  = "branch3Nva"
  branch3_dns_hostname  = "branch3Dns"
  branch3_vm_fqdn       = "${local.branch3_vm_hostname}.${local.onprem_domain}"
}

# spoke1
#----------------------------

locals {
  spoke1_prefix        = var.prefix == "" ? "spoke1-" : join("-", [var.prefix, "spoke1-"])
  spoke1_region        = local.region1
  spoke1_cidr          = ["10.1.0.0/16", ]
  spoke1_ipv6_cidr     = ["2000:abc:1::/56", ]
  spoke1_bgp_community = "12076:20001"
  spoke1_dns_zone      = local.region1_dns_zone
  spoke1_subnets = {
    ("MainSubnetA")        = { cidr = "10.1.0.0/24", ipv6_cidr = "2000:abc:1:0::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("MainSubnetB")        = { cidr = "10.1.1.0/24", ipv6_cidr = "2000:abc:1:1::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("UntrustSubnetA")     = { cidr = "10.1.2.0/24", ipv6_cidr = "2000:abc:1:2::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("UntrustSubnetB")     = { cidr = "10.1.3.0/24", ipv6_cidr = "2000:abc:1:3::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("TrustSubnetA")       = { cidr = "10.1.4.0/24", ipv6_cidr = "2000:abc:1:4::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("TrustSubnetB")       = { cidr = "10.1.5.0/24", ipv6_cidr = "2000:abc:1:5::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ManagementSubnetA")  = { cidr = "10.1.6.0/24", ipv6_cidr = "2000:abc:1:6::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("ManagementSubnetB")  = { cidr = "10.1.7.0/24", ipv6_cidr = "2000:abc:1:7::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("DnsInboundSubnetA")  = { cidr = "10.1.8.0/24", ipv6_cidr = "2000:abc:1:8::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("DnsInboundSubnetB")  = { cidr = "10.1.9.0/24", ipv6_cidr = "2000:abc:1:9::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("DnsOutboundSubnetA") = { cidr = "10.1.10.0/24", ipv6_cidr = "2000:abc:1:10::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("DnsOutboundSubnetB") = { cidr = "10.1.11.0/24", ipv6_cidr = "2000:abc:1:11::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ExternalALBSubnetA") = { cidr = "10.1.12.0/24", ipv6_cidr = "2000:abc:1:12::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("ExternalALBSubnetB") = { cidr = "10.1.13.0/24", ipv6_cidr = "2000:abc:1:13::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("InternalALBSubnetA") = { cidr = "10.1.14.0/24", ipv6_cidr = "2000:abc:1:14::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("InternalALBSubnetB") = { cidr = "10.1.15.0/24", ipv6_cidr = "2000:abc:1:15::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ExternalNLBSubnetA") = { cidr = "10.1.16.0/24", ipv6_cidr = "2000:abc:1:16::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("ExternalNLBSubnetB") = { cidr = "10.1.17.0/24", ipv6_cidr = "2000:abc:1:17::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("InternalNLBSubnetA") = { cidr = "10.1.18.0/24", ipv6_cidr = "2000:abc:1:18::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("InternalNLBSubnetB") = { cidr = "10.1.19.0/24", ipv6_cidr = "2000:abc:1:19::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("EndpointSubnetA")    = { cidr = "10.1.20.0/24", ipv6_cidr = "2000:abc:1:20::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("EndpointSubnetB")    = { cidr = "10.1.21.0/24", ipv6_cidr = "2000:abc:1:21::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("AksSubnetA")         = { cidr = "10.1.80.0/20", ipv6_cidr = "2000:abc:1:80::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("AksSubnetB")         = { cidr = "10.1.96.0/20", ipv6_cidr = "2000:abc:1:96::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
  }
  spoke1_vm_addr        = cidrhost(local.spoke1_subnets["MainSubnetA"].cidr, 5)
  spoke1_int_nlb_addr_a = cidrhost(local.spoke1_subnets["InternalNLBSubnetA"].cidr, 99)
  spoke1_int_nlb_addr_b = cidrhost(local.spoke1_subnets["InternalNLBSubnetB"].cidr, 99)
  spoke1_int_alb_addr_a = cidrhost(local.spoke1_subnets["InternalALBSubnetA"].cidr, 99)
  spoke1_int_alb_addr_b = cidrhost(local.spoke1_subnets["InternalALBSubnetB"].cidr, 99)
  spoke1_ext_nlb_addr_a = cidrhost(local.spoke1_subnets["ExternalNLBSubnetA"].cidr, 99)
  spoke1_ext_nlb_addr_b = cidrhost(local.spoke1_subnets["ExternalNLBSubnetB"].cidr, 99)
  spoke1_ext_alb_addr_a = cidrhost(local.spoke1_subnets["ExternalALBSubnetA"].cidr, 99)
  spoke1_ext_alb_addr_b = cidrhost(local.spoke1_subnets["ExternalALBSubnetB"].cidr, 99)

  spoke1_vm_addr_v6        = cidrhost(local.spoke1_subnets["MainSubnetA"].ipv6_cidr, 5)
  spoke1_int_nlb_addr_a_v6 = cidrhost(local.spoke1_subnets["InternalNLBSubnetA"].ipv6_cidr, 153)
  spoke1_int_alb_addr_v6   = cidrhost(local.spoke1_subnets["InternalALBSubnetA"].ipv6_cidr, 153)

  spoke1_pl_nat_addr      = cidrhost(local.spoke1_subnets["MainSubnetA"].cidr, 50)
  spoke1_vm_hostname      = "spoke1Vm"
  spoke1_int_nlb_hostname = "spoke1-ilb"
  spoke1_vm_fqdn          = "${local.spoke1_vm_hostname}.${local.spoke1_dns_zone}"
}

# spoke2
#----------------------------

locals {
  spoke2_prefix        = var.prefix == "" ? "spoke2-" : join("-", [var.prefix, "spoke2-"])
  spoke2_region        = local.region1
  spoke2_cidr          = ["10.2.0.0/16", ]
  spoke2_ipv6_cidr     = ["2000:abc:2::/56", ]
  spoke2_bgp_community = "12076:20002"
  spoke2_dns_zone      = local.region1_dns_zone
  spoke2_subnets = {
    ("MainSubnetA")        = { cidr = "10.2.0.0/24", ipv6_cidr = "2000:abc:2:0::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("MainSubnetB")        = { cidr = "10.2.1.0/24", ipv6_cidr = "2000:abc:2:1::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("UntrustSubnetA")     = { cidr = "10.2.2.0/24", ipv6_cidr = "2000:abc:2:2::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("UntrustSubnetB")     = { cidr = "10.2.3.0/24", ipv6_cidr = "2000:abc:2:3::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("TrustSubnetA")       = { cidr = "10.2.4.0/24", ipv6_cidr = "2000:abc:2:4::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("TrustSubnetB")       = { cidr = "10.2.5.0/24", ipv6_cidr = "2000:abc:2:5::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ManagementSubnetA")  = { cidr = "10.2.6.0/24", ipv6_cidr = "2000:abc:2:6::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("ManagementSubnetB")  = { cidr = "10.2.7.0/24", ipv6_cidr = "2000:abc:2:7::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("DnsInboundSubnetA")  = { cidr = "10.2.8.0/24", ipv6_cidr = "2000:abc:2:8::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("DnsInboundSubnetB")  = { cidr = "10.2.9.0/24", ipv6_cidr = "2000:abc:2:9::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("DnsOutboundSubnetA") = { cidr = "10.2.10.0/24", ipv6_cidr = "2000:abc:2:10::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("DnsOutboundSubnetB") = { cidr = "10.2.11.0/24", ipv6_cidr = "2000:abc:2:11::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ExternalALBSubnetA") = { cidr = "10.2.12.0/24", ipv6_cidr = "2000:abc:2:12::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("ExternalALBSubnetB") = { cidr = "10.2.13.0/24", ipv6_cidr = "2000:abc:2:13::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("InternalALBSubnetA") = { cidr = "10.2.14.0/24", ipv6_cidr = "2000:abc:2:14::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("InternalALBSubnetB") = { cidr = "10.2.15.0/24", ipv6_cidr = "2000:abc:2:15::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ExternalNLBSubnetA") = { cidr = "10.2.16.0/24", ipv6_cidr = "2000:abc:2:16::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("ExternalNLBSubnetB") = { cidr = "10.2.17.0/24", ipv6_cidr = "2000:abc:2:17::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("InternalNLBSubnetA") = { cidr = "10.2.18.0/24", ipv6_cidr = "2000:abc:2:18::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("InternalNLBSubnetB") = { cidr = "10.2.19.0/24", ipv6_cidr = "2000:abc:2:19::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("EndpointSubnetA")    = { cidr = "10.2.20.0/24", ipv6_cidr = "2000:abc:2:20::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("EndpointSubnetB")    = { cidr = "10.2.21.0/24", ipv6_cidr = "2000:abc:2:21::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("AksSubnetA")         = { cidr = "10.2.80.0/20", ipv6_cidr = "2000:abc:2:80::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("AksSubnetB")         = { cidr = "10.2.96.0/20", ipv6_cidr = "2000:abc:2:96::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
  }
  spoke2_vm_addr        = cidrhost(local.spoke2_subnets["MainSubnetA"].cidr, 5)
  spoke2_int_nlb_addr_a = cidrhost(local.spoke2_subnets["InternalNLBSubnetA"].cidr, 99)
  spoke2_int_nlb_addr_b = cidrhost(local.spoke2_subnets["InternalNLBSubnetB"].cidr, 99)
  spoke2_int_alb_addr_a = cidrhost(local.spoke2_subnets["InternalALBSubnetA"].cidr, 99)
  spoke2_int_alb_addr_b = cidrhost(local.spoke2_subnets["InternalALBSubnetB"].cidr, 99)
  spoke2_ext_nlb_addr_a = cidrhost(local.spoke2_subnets["ExternalNLBSubnetA"].cidr, 99)
  spoke2_ext_nlb_addr_b = cidrhost(local.spoke2_subnets["ExternalNLBSubnetB"].cidr, 99)
  spoke2_ext_alb_addr_a = cidrhost(local.spoke2_subnets["ExternalALBSubnetA"].cidr, 99)
  spoke2_ext_alb_addr_b = cidrhost(local.spoke2_subnets["ExternalALBSubnetB"].cidr, 99)

  spoke2_vm_addr_v6        = cidrhost(local.spoke2_subnets["MainSubnetA"].ipv6_cidr, 5)
  spoke2_int_nlb_addr_a_v6 = cidrhost(local.spoke2_subnets["InternalNLBSubnetA"].ipv6_cidr, 153)
  spoke2_ext_alb_addr_a_v6 = cidrhost(local.spoke2_subnets["InternalALBSubnetA"].ipv6_cidr, 153)

  spoke2_pl_nat_addr      = cidrhost(local.spoke2_subnets["MainSubnetA"].cidr, 50)
  spoke2_vm_hostname      = "spoke2Vm"
  spoke2_int_nlb_hostname = "spoke2-ilb"
  spoke2_vm_fqdn          = "${local.spoke2_vm_hostname}.${local.spoke2_dns_zone}"
}

# spoke3
#----------------------------

locals {
  spoke3_prefix        = var.prefix == "" ? "spoke3-" : join("-", [var.prefix, "spoke3-"])
  spoke3_region        = local.region1
  spoke3_cidr          = ["10.3.0.0/16", ]
  spoke3_ipv6_cidr     = ["2000:abc:3::/56", ]
  spoke3_bgp_community = "12076:20003"
  spoke3_dns_zone      = local.region1_dns_zone
  spoke3_subnets = {
    ("MainSubnetA")        = { cidr = "10.3.0.0/24", ipv6_cidr = "2000:abc:3:0::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("MainSubnetB")        = { cidr = "10.3.1.0/24", ipv6_cidr = "2000:abc:3:1::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("UntrustSubnetA")     = { cidr = "10.3.2.0/24", ipv6_cidr = "2000:abc:3:2::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("UntrustSubnetB")     = { cidr = "10.3.3.0/24", ipv6_cidr = "2000:abc:3:3::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("TrustSubnetA")       = { cidr = "10.3.4.0/24", ipv6_cidr = "2000:abc:3:4::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("TrustSubnetB")       = { cidr = "10.3.5.0/24", ipv6_cidr = "2000:abc:3:5::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ManagementSubnetA")  = { cidr = "10.3.6.0/24", ipv6_cidr = "2000:abc:3:6::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("ManagementSubnetB")  = { cidr = "10.3.7.0/24", ipv6_cidr = "2000:abc:3:7::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("DnsInboundSubnetA")  = { cidr = "10.3.8.0/24", ipv6_cidr = "2000:abc:3:8::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("DnsInboundSubnetB")  = { cidr = "10.3.9.0/24", ipv6_cidr = "2000:abc:3:9::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("DnsOutboundSubnetA") = { cidr = "10.3.10.0/24", ipv6_cidr = "2000:abc:3:10::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("DnsOutboundSubnetB") = { cidr = "10.3.11.0/24", ipv6_cidr = "2000:abc:3:11::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ExternalALBSubnetA") = { cidr = "10.3.12.0/24", ipv6_cidr = "2000:abc:3:12::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("ExternalALBSubnetB") = { cidr = "10.3.13.0/24", ipv6_cidr = "2000:abc:3:13::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("InternalALBSubnetA") = { cidr = "10.3.14.0/24", ipv6_cidr = "2000:abc:3:14::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("InternalALBSubnetB") = { cidr = "10.3.15.0/24", ipv6_cidr = "2000:abc:3:15::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ExternalNLBSubnetA") = { cidr = "10.3.16.0/24", ipv6_cidr = "2000:abc:3:16::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("ExternalNLBSubnetB") = { cidr = "10.3.17.0/24", ipv6_cidr = "2000:abc:3:17::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("InternalNLBSubnetA") = { cidr = "10.3.18.0/24", ipv6_cidr = "2000:abc:3:18::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("InternalNLBSubnetB") = { cidr = "10.3.19.0/24", ipv6_cidr = "2000:abc:3:19::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("EndpointSubnetA")    = { cidr = "10.3.20.0/24", ipv6_cidr = "2000:abc:3:20::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("EndpointSubnetB")    = { cidr = "10.3.21.0/24", ipv6_cidr = "2000:abc:3:21::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("AksSubnetA")         = { cidr = "10.3.80.0/20", ipv6_cidr = "2000:abc:3:80::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("AksSubnetB")         = { cidr = "10.3.96.0/20", ipv6_cidr = "2000:abc:3:96::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
  }
  spoke3_vm_addr        = cidrhost(local.spoke3_subnets["MainSubnetA"].cidr, 5)
  spoke3_int_nlb_addr_a = cidrhost(local.spoke3_subnets["InternalNLBSubnetA"].cidr, 99)
  spoke3_int_nlb_addr_b = cidrhost(local.spoke3_subnets["InternalNLBSubnetB"].cidr, 99)
  spoke3_int_alb_addr_a = cidrhost(local.spoke3_subnets["InternalALBSubnetA"].cidr, 99)
  spoke3_int_alb_addr_b = cidrhost(local.spoke3_subnets["InternalALBSubnetB"].cidr, 99)
  spoke3_ext_nlb_addr_a = cidrhost(local.spoke3_subnets["ExternalNLBSubnetA"].cidr, 99)
  spoke3_ext_nlb_addr_b = cidrhost(local.spoke3_subnets["ExternalNLBSubnetB"].cidr, 99)
  spoke3_ext_alb_addr_a = cidrhost(local.spoke3_subnets["ExternalALBSubnetA"].cidr, 99)
  spoke3_ext_alb_addr_b = cidrhost(local.spoke3_subnets["ExternalALBSubnetB"].cidr, 99)

  spoke3_vm_addr_v6        = cidrhost(local.spoke3_subnets["MainSubnetA"].ipv6_cidr, 5)
  spoke3_int_nlb_addr_a_v6 = cidrhost(local.spoke3_subnets["InternalNLBSubnetA"].ipv6_cidr, 153)
  spoke3_ext_alb_addr_a_v6 = cidrhost(local.spoke3_subnets["InternalALBSubnetA"].ipv6_cidr, 153)

  spoke3_pl_nat_addr      = cidrhost(local.spoke3_subnets["MainSubnetA"].cidr, 50)
  spoke3_vm_hostname      = "spoke3Vm"
  spoke3_int_nlb_hostname = "spoke3-ilb"
  spoke3_vm_fqdn          = "${local.spoke3_vm_hostname}.${local.spoke3_dns_zone}"
}

# spoke4
#----------------------------

locals {
  spoke4_prefix        = var.prefix == "" ? "spoke4-" : join("-", [var.prefix, "spoke4-"])
  spoke4_region        = local.region2
  spoke4_cidr          = ["10.4.0.0/16", ]
  spoke4_ipv6_cidr     = ["2000:abc:4::/56", ]
  spoke4_bgp_community = "12076:20004"
  spoke4_dns_zone      = local.region2_dns_zone
  spoke4_subnets = {
    ("MainSubnetA")        = { cidr = "10.4.0.0/24", ipv6_cidr = "2000:abc:4:0::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("MainSubnetB")        = { cidr = "10.4.1.0/24", ipv6_cidr = "2000:abc:4:1::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("UntrustSubnetA")     = { cidr = "10.4.2.0/24", ipv6_cidr = "2000:abc:4:2::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("UntrustSubnetB")     = { cidr = "10.4.3.0/24", ipv6_cidr = "2000:abc:4:3::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("TrustSubnetA")       = { cidr = "10.4.4.0/24", ipv6_cidr = "2000:abc:4:4::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("TrustSubnetB")       = { cidr = "10.4.5.0/24", ipv6_cidr = "2000:abc:4:5::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ManagementSubnetA")  = { cidr = "10.4.6.0/24", ipv6_cidr = "2000:abc:4:6::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("ManagementSubnetB")  = { cidr = "10.4.7.0/24", ipv6_cidr = "2000:abc:4:7::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("DnsInboundSubnetA")  = { cidr = "10.4.8.0/24", ipv6_cidr = "2000:abc:4:8::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("DnsInboundSubnetB")  = { cidr = "10.4.9.0/24", ipv6_cidr = "2000:abc:4:9::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("DnsOutboundSubnetA") = { cidr = "10.4.10.0/24", ipv6_cidr = "2000:abc:4:10::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("DnsOutboundSubnetB") = { cidr = "10.4.11.0/24", ipv6_cidr = "2000:abc:4:11::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ExternalALBSubnetA") = { cidr = "10.4.12.0/24", ipv6_cidr = "2000:abc:4:12::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("ExternalALBSubnetB") = { cidr = "10.4.13.0/24", ipv6_cidr = "2000:abc:4:13::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("InternalALBSubnetA") = { cidr = "10.4.14.0/24", ipv6_cidr = "2000:abc:4:14::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("InternalALBSubnetB") = { cidr = "10.4.15.0/24", ipv6_cidr = "2000:abc:4:15::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ExternalNLBSubnetA") = { cidr = "10.4.16.0/24", ipv6_cidr = "2000:abc:4:16::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("ExternalNLBSubnetB") = { cidr = "10.4.17.0/24", ipv6_cidr = "2000:abc:4:17::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("InternalNLBSubnetA") = { cidr = "10.4.18.0/24", ipv6_cidr = "2000:abc:4:18::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("InternalNLBSubnetB") = { cidr = "10.4.19.0/24", ipv6_cidr = "2000:abc:4:19::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("EndpointSubnetA")    = { cidr = "10.4.20.0/24", ipv6_cidr = "2000:abc:4:20::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("EndpointSubnetB")    = { cidr = "10.4.21.0/24", ipv6_cidr = "2000:abc:4:21::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("AksSubnetA")         = { cidr = "10.4.80.0/20", ipv6_cidr = "2000:abc:4:80::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("AksSubnetB")         = { cidr = "10.4.96.0/20", ipv6_cidr = "2000:abc:4:96::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
  }
  spoke4_vm_addr        = cidrhost(local.spoke4_subnets["MainSubnetA"].cidr, 5)
  spoke4_int_nlb_addr_a = cidrhost(local.spoke4_subnets["InternalNLBSubnetA"].cidr, 99)
  spoke4_int_nlb_addr_b = cidrhost(local.spoke4_subnets["InternalNLBSubnetB"].cidr, 99)
  spoke4_int_alb_addr_a = cidrhost(local.spoke4_subnets["InternalALBSubnetA"].cidr, 99)
  spoke4_int_alb_addr_b = cidrhost(local.spoke4_subnets["InternalALBSubnetB"].cidr, 99)
  spoke4_ext_nlb_addr_a = cidrhost(local.spoke4_subnets["ExternalNLBSubnetA"].cidr, 99)
  spoke4_ext_nlb_addr_b = cidrhost(local.spoke4_subnets["ExternalNLBSubnetB"].cidr, 99)
  spoke4_ext_alb_addr_a = cidrhost(local.spoke4_subnets["ExternalALBSubnetA"].cidr, 99)
  spoke4_ext_alb_addr_b = cidrhost(local.spoke4_subnets["ExternalALBSubnetB"].cidr, 99)

  spoke4_vm_addr_v6        = cidrhost(local.spoke4_subnets["MainSubnetA"].ipv6_cidr, 5)
  spoke4_int_nlb_addr_a_v6 = cidrhost(local.spoke4_subnets["InternalNLBSubnetA"].ipv6_cidr, 153)
  spoke4_ext_alb_addr_a_v6 = cidrhost(local.spoke4_subnets["InternalALBSubnetA"].ipv6_cidr, 153)

  spoke4_pl_nat_addr      = cidrhost(local.spoke4_subnets["MainSubnetA"].cidr, 50)
  spoke4_vm_hostname      = "spoke4Vm"
  spoke4_int_nlb_hostname = "spoke4-ilb"
  spoke4_vm_fqdn          = "${local.spoke4_vm_hostname}.${local.spoke4_dns_zone}"
}

# spoke5
#----------------------------

locals {
  spoke5_prefix        = var.prefix == "" ? "spoke5-" : join("-", [var.prefix, "spoke5-"])
  spoke5_region        = local.region2
  spoke5_cidr          = ["10.5.0.0/16", ]
  spoke5_ipv6_cidr     = ["2000:abc:5::/56", ]
  spoke5_bgp_community = "12076:20005"
  spoke5_dns_zone      = local.region2_dns_zone
  spoke5_subnets = {
    ("MainSubnetA")        = { cidr = "10.5.0.0/24", ipv6_cidr = "2000:abc:5:0::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("MainSubnetB")        = { cidr = "10.5.1.0/24", ipv6_cidr = "2000:abc:5:1::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("UntrustSubnetA")     = { cidr = "10.5.2.0/24", ipv6_cidr = "2000:abc:5:2::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("UntrustSubnetB")     = { cidr = "10.5.3.0/24", ipv6_cidr = "2000:abc:5:3::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("TrustSubnetA")       = { cidr = "10.5.4.0/24", ipv6_cidr = "2000:abc:5:4::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("TrustSubnetB")       = { cidr = "10.5.5.0/24", ipv6_cidr = "2000:abc:5:5::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ManagementSubnetA")  = { cidr = "10.5.6.0/24", ipv6_cidr = "2000:abc:5:6::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("ManagementSubnetB")  = { cidr = "10.5.7.0/24", ipv6_cidr = "2000:abc:5:7::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("DnsInboundSubnetA")  = { cidr = "10.5.8.0/24", ipv6_cidr = "2000:abc:5:8::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("DnsInboundSubnetB")  = { cidr = "10.5.9.0/24", ipv6_cidr = "2000:abc:5:9::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("DnsOutboundSubnetA") = { cidr = "10.5.10.0/24", ipv6_cidr = "2000:abc:5:10::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("DnsOutboundSubnetB") = { cidr = "10.5.11.0/24", ipv6_cidr = "2000:abc:5:11::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ExternalALBSubnetA") = { cidr = "10.5.12.0/24", ipv6_cidr = "2000:abc:5:12::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("ExternalALBSubnetB") = { cidr = "10.5.13.0/24", ipv6_cidr = "2000:abc:5:13::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("InternalALBSubnetA") = { cidr = "10.5.14.0/24", ipv6_cidr = "2000:abc:5:14::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("InternalALBSubnetB") = { cidr = "10.5.15.0/24", ipv6_cidr = "2000:abc:5:15::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ExternalNLBSubnetA") = { cidr = "10.5.16.0/24", ipv6_cidr = "2000:abc:5:16::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("ExternalNLBSubnetB") = { cidr = "10.5.17.0/24", ipv6_cidr = "2000:abc:5:17::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("InternalNLBSubnetA") = { cidr = "10.5.18.0/24", ipv6_cidr = "2000:abc:5:18::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("InternalNLBSubnetB") = { cidr = "10.5.19.0/24", ipv6_cidr = "2000:abc:5:19::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("EndpointSubnetA")    = { cidr = "10.5.20.0/24", ipv6_cidr = "2000:abc:5:20::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("EndpointSubnetB")    = { cidr = "10.5.21.0/24", ipv6_cidr = "2000:abc:5:21::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("AksSubnetA")         = { cidr = "10.5.80.0/20", ipv6_cidr = "2000:abc:5:80::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("AksSubnetB")         = { cidr = "10.5.96.0/20", ipv6_cidr = "2000:abc:5:96::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
  }
  spoke5_vm_addr        = cidrhost(local.spoke5_subnets["MainSubnetA"].cidr, 5)
  spoke5_int_nlb_addr_a = cidrhost(local.spoke5_subnets["InternalNLBSubnetA"].cidr, 99)
  spoke5_int_nlb_addr_b = cidrhost(local.spoke5_subnets["InternalNLBSubnetB"].cidr, 99)
  spoke5_int_alb_addr_a = cidrhost(local.spoke5_subnets["InternalALBSubnetA"].cidr, 99)
  spoke5_int_alb_addr_b = cidrhost(local.spoke5_subnets["InternalALBSubnetB"].cidr, 99)
  spoke5_ext_nlb_addr_a = cidrhost(local.spoke5_subnets["ExternalNLBSubnetA"].cidr, 99)
  spoke5_ext_nlb_addr_b = cidrhost(local.spoke5_subnets["ExternalNLBSubnetB"].cidr, 99)
  spoke5_ext_alb_addr_a = cidrhost(local.spoke5_subnets["ExternalALBSubnetA"].cidr, 99)
  spoke5_ext_alb_addr_b = cidrhost(local.spoke5_subnets["ExternalALBSubnetB"].cidr, 99)

  spoke5_vm_addr_v6        = cidrhost(local.spoke5_subnets["MainSubnetA"].ipv6_cidr, 5)
  spoke5_int_nlb_addr_a_v6 = cidrhost(local.spoke5_subnets["InternalNLBSubnetA"].ipv6_cidr, 153)
  spoke5_ext_alb_addr_a_v6 = cidrhost(local.spoke5_subnets["InternalALBSubnetA"].ipv6_cidr, 153)

  spoke5_pl_nat_addr      = cidrhost(local.spoke5_subnets["MainSubnetA"].cidr, 50)
  spoke5_vm_hostname      = "spoke5Vm"
  spoke5_int_nlb_hostname = "spoke5-ilb"
  spoke5_vm_fqdn          = "${local.spoke5_vm_hostname}.${local.spoke5_dns_zone}"
}

# spoke6
#----------------------------

locals {
  spoke6_prefix        = var.prefix == "" ? "spoke6-" : join("-", [var.prefix, "spoke6-"])
  spoke6_region        = local.region2
  spoke6_cidr          = ["10.6.0.0/16", ]
  spoke6_ipv6_cidr     = ["2000:abc:6::/56", ]
  spoke6_bgp_community = "12076:20006"
  spoke6_dns_zone      = local.region2_dns_zone
  spoke6_subnets = {
    ("MainSubnetA")        = { cidr = "10.6.0.0/24", ipv6_cidr = "2000:abc:6:0::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("MainSubnetB")        = { cidr = "10.6.1.0/24", ipv6_cidr = "2000:abc:6:1::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("UntrustSubnetA")     = { cidr = "10.6.2.0/24", ipv6_cidr = "2000:abc:6:2::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("UntrustSubnetB")     = { cidr = "10.6.3.0/24", ipv6_cidr = "2000:abc:6:3::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("TrustSubnetA")       = { cidr = "10.6.4.0/24", ipv6_cidr = "2000:abc:6:4::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("TrustSubnetB")       = { cidr = "10.6.5.0/24", ipv6_cidr = "2000:abc:6:5::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ManagementSubnetA")  = { cidr = "10.6.6.0/24", ipv6_cidr = "2000:abc:6:6::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("ManagementSubnetB")  = { cidr = "10.6.7.0/24", ipv6_cidr = "2000:abc:6:7::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("DnsInboundSubnetA")  = { cidr = "10.6.8.0/24", ipv6_cidr = "2000:abc:6:8::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("DnsInboundSubnetB")  = { cidr = "10.6.9.0/24", ipv6_cidr = "2000:abc:6:9::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("DnsOutboundSubnetA") = { cidr = "10.6.10.0/24", ipv6_cidr = "2000:abc:6:10::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("DnsOutboundSubnetB") = { cidr = "10.6.11.0/24", ipv6_cidr = "2000:abc:6:11::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ExternalALBSubnetA") = { cidr = "10.6.12.0/24", ipv6_cidr = "2000:abc:6:12::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("ExternalALBSubnetB") = { cidr = "10.6.13.0/24", ipv6_cidr = "2000:abc:6:13::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("InternalALBSubnetA") = { cidr = "10.6.14.0/24", ipv6_cidr = "2000:abc:6:14::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("InternalALBSubnetB") = { cidr = "10.6.15.0/24", ipv6_cidr = "2000:abc:6:15::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("ExternalNLBSubnetA") = { cidr = "10.6.16.0/24", ipv6_cidr = "2000:abc:6:16::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "public", }
    ("ExternalNLBSubnetB") = { cidr = "10.6.17.0/24", ipv6_cidr = "2000:abc:6:17::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "public", }
    ("InternalNLBSubnetA") = { cidr = "10.6.18.0/24", ipv6_cidr = "2000:abc:6:18::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("InternalNLBSubnetB") = { cidr = "10.6.19.0/24", ipv6_cidr = "2000:abc:6:19::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("EndpointSubnetA")    = { cidr = "10.6.20.0/24", ipv6_cidr = "2000:abc:6:20::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("EndpointSubnetB")    = { cidr = "10.6.21.0/24", ipv6_cidr = "2000:abc:6:21::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
    ("AksSubnetA")         = { cidr = "10.6.80.0/20", ipv6_cidr = "2000:abc:6:80::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "a", scope = "private", }
    ("AksSubnetB")         = { cidr = "10.6.96.0/20", ipv6_cidr = "2000:abc:6:96::/64", ipv6_newbits = 8, ipv6_netnum = 0, az = "b", scope = "private", }
  }
  spoke6_vm_addr        = cidrhost(local.spoke6_subnets["MainSubnetA"].cidr, 5)
  spoke6_int_nlb_addr_a = cidrhost(local.spoke6_subnets["InternalNLBSubnetA"].cidr, 99)
  spoke6_int_nlb_addr_b = cidrhost(local.spoke6_subnets["InternalNLBSubnetB"].cidr, 99)
  spoke6_int_alb_addr_a = cidrhost(local.spoke6_subnets["InternalALBSubnetA"].cidr, 99)
  spoke6_int_alb_addr_b = cidrhost(local.spoke6_subnets["InternalALBSubnetB"].cidr, 99)
  spoke6_ext_nlb_addr_a = cidrhost(local.spoke6_subnets["ExternalNLBSubnetA"].cidr, 99)
  spoke6_ext_nlb_addr_b = cidrhost(local.spoke6_subnets["ExternalNLBSubnetB"].cidr, 99)
  spoke6_ext_alb_addr_a = cidrhost(local.spoke6_subnets["ExternalALBSubnetA"].cidr, 99)
  spoke6_ext_alb_addr_b = cidrhost(local.spoke6_subnets["ExternalALBSubnetB"].cidr, 99)

  spoke6_vm_addr_v6        = cidrhost(local.spoke6_subnets["MainSubnetA"].ipv6_cidr, 5)
  spoke6_int_nlb_addr_a_v6 = cidrhost(local.spoke6_subnets["InternalNLBSubnetA"].ipv6_cidr, 153)
  spoke6_ext_alb_addr_a_v6 = cidrhost(local.spoke6_subnets["InternalALBSubnetA"].ipv6_cidr, 153)

  spoke6_pl_nat_addr      = cidrhost(local.spoke6_subnets["MainSubnetA"].cidr, 50)
  spoke6_vm_hostname      = "spoke6Vm"
  spoke6_int_nlb_hostname = "spoke6-ilb"
  spoke6_vm_fqdn          = "${local.spoke6_vm_hostname}.${local.spoke6_dns_zone}"
}
