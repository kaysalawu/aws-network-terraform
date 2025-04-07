

g2-netbox$ aws ec2 describe-images --image-ids ami-0a48818358b2711d7 --query 'Images[*]' --output json --region eu-west-1 --output table
------------------------------------------------------------------------------------------------------------------------
|                                                    DescribeImages                                                    |
+--------------------+-------------------------------------------------------------------------------------------------+
|  Architecture      |  x86_64                                                                                         |
|  CreationDate      |  2024-02-18T23:56:06.000Z                                                                       |
|  DeprecationTime   |  2026-02-18T23:56:06.000Z                                                                       |
|  EnaSupport        |  True                                                                                           |
|  Hypervisor        |  xen                                                                                            |
|  ImageId           |  ami-0a48818358b2711d7                                                                          |
|  ImageLocation     |  aws-marketplace/Arara Solutions - Ubuntu 22.04 - NetBox community - v0224-prod-jz3khonabosm6   |
|  ImageOwnerAlias   |  aws-marketplace                                                                                |
|  ImageType         |  machine                                                                                        |
|  Name              |  Arara Solutions - Ubuntu 22.04 - NetBox community - v0224-prod-jz3khonabosm6                   |
|  OwnerId           |  679593333241                                                                                   |
|  PlatformDetails   |  Linux/UNIX                                                                                     |
|  Public            |  True                                                                                           |
|  RootDeviceName    |  /dev/sda1                                                                                      |
|  RootDeviceType    |  ebs                                                                                            |
|  SriovNetSupport   |  simple                                                                                         |
|  State             |  available                                                                                      |
|  UsageOperation    |  RunInstances                                                                                   |
|  VirtualizationType|  hvm                                                                                            |
+--------------------+-------------------------------------------------------------------------------------------------+
||                                                 BlockDeviceMappings                                                ||
|+-------------------------------------------------------------+------------------------------------------------------+|
||  DeviceName                                                 |  /dev/sda1                                           ||
||  VirtualName                                                |                                                      ||
|+-------------------------------------------------------------+------------------------------------------------------+|
|||                                                        Ebs                                                       |||
||+----------------------------------------------------+-------------------------------------------------------------+||
|||  DeleteOnTermination                               |  True                                                       |||
|||  Encrypted                                         |  False                                                      |||
|||  SnapshotId                                        |  snap-08cec2da52e3fb27a                                     |||
|||  VolumeSize                                        |  32                                                         |||
|||  VolumeType                                        |  gp2                                                        |||
||+----------------------------------------------------+-------------------------------------------------------------+||
||                                                 BlockDeviceMappings                                                ||
|+-----------------------------------------------------------+--------------------------------------------------------+|
||  DeviceName                                               |  /dev/sdb                                              ||
||  VirtualName                                              |  ephemeral0                                            ||
|+-----------------------------------------------------------+--------------------------------------------------------+|
||                                                 BlockDeviceMappings                                                ||
|+-----------------------------------------------------------+--------------------------------------------------------+|
||  DeviceName                                               |  /dev/sdc                                              ||
||  VirtualName                                              |  ephemeral1                                            ||
|+-----------------------------------------------------------+--------------------------------------------------------+|
||                                                    ProductCodes                                                    ||
|+---------------------------------------------+----------------------------------------------------------------------+|
||  ProductCodeId                              |  eb9vvg3uzzob1xn79dqr39rpz                                           ||
||  ProductCodeType                            |  marketplace                                                         ||
|+---------------------------------------------+----------------------------------------------------------------------+|
