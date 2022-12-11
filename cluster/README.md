# EKS CLUSTER

- [EKS CLUSTER](#eks-cluster)
  - [CLUSTER](#cluster)
  - [NODE GROUP](#node-group)
  - [VPC ENDPOINTS](#vpc-endpoints)
    - [CLOUDFORMATION STACK](#cloudformation-stack)
    - [CLOUDFORMATION PARAMETERS](#cloudformation-parameters)

## CLUSTER
1. To create an **EKS cluster**, please use the below command.
   ```
   eksctl create cluster -f cluster.yaml
   ```
2. The process should be within 15 minutes if the definition file is simple.
3. Once the creation is done, we need to verify.
   ```
   eksctl get cluster -n <EKS_CLUSTER_NAME>
   ```
4. The output should be as follows:
   ```
   2021-05-10 10:28:55 [ℹ]  eksctl version 0.44.0
   2021-05-10 10:28:55 [ℹ]  using region ap-southeast-1
   NAME        VERSION STATUS  CREATED                 VPC                   SUBNETS                                           SECURITYGROUPS
   eks-cluster 1.18    ACTIVE  2021-05-05T01:30:44Z    vpc-0f12345ed12345678 subnet-,subnet-,subnet-,subnet-,subnet-,subnet-   sg-0a1bc12d345ef7890
   ```

> Because the **eksctl** timeout is within 25 minutes, we need to keep the definition file simple. If there are any advanced requirements, please use AWS console to modify.

For example, from our definition file, we have to comment out the following 3 lines. Then, we update the [cluster endpoints access](https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html) using AWS console.
```
#  clusterEndpoints:
#     privateAccess: true
#     publicAccess: true
```

## NODE GROUP
1. To create an **EKS node group**, please use the below command.
   ```
   eksctl create nodegroup -f node_groups.yaml
   ```
2. The process should be within 10 minutes.
3. Once the creation is done, we need to verify.
   ```
   eksctl get nodegroup --cluster <EKS_CLUSTER_NAME>
   ```
4. The output should be as follows:
   ```
   2021-05-10 10:28:55 [ℹ]  eksctl version 0.44.0
   2021-05-10 10:28:55 [ℹ]  using region ap-southeast-1
   CLUSTER     NODEGROUP       STATUS          CREATED                 MIN SIZE  MAX SIZE  DESIRED CAPACITY  INSTANCE TYPE  IMAGE ID  ASG NAME
   eks-cluster eks-nodegroup   CREATE_COMPLETE 2021-05-05T07:40:10Z    1         6         2                 m5.2xlarge               eks-a1bc2d4e
   ```

## VPC ENDPOINTS
If **cluster endpoint access** is `Private` and **managed node group** requires `privateNetworking`, we need to deploy VPC endpoints.

Let's assume the region is Singapore (ap-southeast-1). Here are the list of endpoints provision.
| Endpoint Service | Type |
| ---------------- | ---- |
| com.amazonaws.ap-southeast-1.s3 | Gateway |
| com.amazonaws.ap-southeast-1.logs | Interface |
| com.amazonaws.ap-southeast-1.ecr.dkr | Interface |
| com.amazonaws.ap-southeast-1.ecr.api | Interface |
| com.amazonaws.ap-southeast-1.ec2 | Interface |
| com.amazonaws.ap-southeast-1.sts | Interface |

### CLOUDFORMATION STACK
Using **AWS console**, we access [CloudFormation](https://console.aws.amazon.com/cloudformation/) service.
1. Click `Create Stack with new resources (standard)`.
2. At step 1, 
   1. **Prerequisite - Prepare template**, select `Template is ready`.
   2. **Specify template**, select `Upload a template file`.
3. At step 2,
   1. **Stack name**, input the name.
   2. **Parameters**, please follow the below table. 

Using **AWS CLI**, we can create a *CloudFormation Stack* to automate all required endpoints provision.
```
aws cloudformation create-stack --stack-name eks-vpc-endpoints \
    --template-body file://endpoints.yaml \
    --parameters ParameterKey=VpcId,ParameterValue=<VPC_ID> \
    ParameterKey=VpcBlock,ParameterValue=<VPC_CIDR_BLOCK> \
    ParameterKey=PrivateSubnet01Id,ParameterValue=<PRIVATE_SUBNET_1_ID> \
    ParameterKey=PrivateSubnet01Block,ParameterValue=<PRIVATE_SUBNET_1_CIDR> \
    ParameterKey=PrivateSubnet02Id,ParameterValue=<PRIVATE_SUBNET_2_ID> \
    ParameterKey=PrivateSubnet02Block,ParameterValue=<PRIVATE_SUBNET_2_CIDR> \
    ParameterKey=PrivateSubnet03Id,ParameterValue=<PRIVATE_SUBNET_3_ID> \
    ParameterKey=PrivateSubnet03Block,ParameterValue=<PRIVATE_SUBNET_3_CIDR> \
    ParameterKey=PrivateRouteTableId,ParameterValue=<PRIVATE_SUBNET_ROUTE_TABLE> \
    --capabilities CAPABILITY_IAM \
    --region <AWS_REGION>
```

### CLOUDFORMATION PARAMETERS
Here are the required parameters for our CloudFormation stack to be successfully created.
| Parameters | Description |
| ---------- | ----- |
| VpcId | The VPC ID that EKS clusters reside |
| VpcBlock | The VPC CIDR range that EKS clusters reside |
| PrivateSubnet01Id | The private Subnet ID under AZ A |
| PrivateSubnet01Block | The private Subnet CIDR range under AZ A |
| PrivateSubnet02Id | The private Subnet ID under AZ B |
| PrivateSubnet02Block | The private Subnet CIDR range under AZ B |
| PrivateSubnet03Id | The private Subnet ID under AZ C |
| PrivateSubnet03Block | The private Subnet CIDR range under AZ C |
| PrivateRouteTableId | The private subnets' custom route table ID |
