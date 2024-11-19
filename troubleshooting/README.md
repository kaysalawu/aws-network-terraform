
# Troubleshooting <!-- omit from toc -->

Error Messages
- [1. Transit Gateway Route - is in invalid state](#1-transit-gateway-route---is-in-invalid-state)


The following are some of the common errors and how to resolve them.


## 1. Transit Gateway Route - is in invalid state

**Error:**

Some terraform modules have data resources that require other resources to be created first. This may result in errors like the example below.

**Example:**

```sh
╷
│ Error: creating EC2 Transit Gateway Route (tgw-rtb-0109ab97eca931ab8_10.30.0.0/16): operation error EC2: CreateTransitGatewayRoute, https response error StatusCode: 400, RequestID: 9a0af5b7-840a-4e69-aa3f-d82d95fac821, api error IncorrectState: tgw-attach-044e1d560c4c2e3dc is in invalid state
│
│   with module.tgw1_routes.aws_ec2_transit_gateway_route.external["hub-to-region2-10.30.0.0/16"],
│   on ../../modules/transit-gateway/main.tf line 202, in resource "aws_ec2_transit_gateway_route" "external":
│  202: resource "aws_ec2_transit_gateway_route" "external" {
```

**Solution:**

Apply terraform again.

```sh
terraform plan
terraform apply
```



