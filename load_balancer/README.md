# LOAD BALANACER

- [LOAD BALANACER](#load-balanacer)
  - [AWS LOAD BALANCER CONTROLLER](#aws-load-balancer-controller)
    - [INSTALLATION](#installation)
    - [VERIFICATION](#verification)
  - [INGRESS](#ingress)
    - [PREREQUISITES](#prerequisites)
      - [SERVICE](#service)
    - [DEPLOYMENT](#deployment)
    - [ANNOTATIONS](#annotations)

## AWS LOAD BALANCER CONTROLLER
[AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/), formerly called **AWS ALB Ingress Controller**, is a controller that helps managing **Elastic Load Balancers** for an *EKS cluster* on AWS.

> [How it works?](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/how-it-works/)

### INSTALLATION
The installation script is named as `controller.sh`. To run it, please use the below commands.
```
chmod 755 controller.sh
./controller.sh
```

> **Security updates**: The controller doesn't receive security updates automatically. You need to manually upgrade to a newer version when it becomes available.

At line 8, there is a variable `CONTROLLER_VERSION`, please update it to latest version manually before the installation.
- Check the latest release from [GitHub](https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases).
- Check the latest update from [Documentation](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/deploy/installation/).

Currently, the controller version is `v2.1.3`.

### VERIFICATION
1. After the installation is done, there are 2 resources that we need to verify.
   1. Controller deployment
   2. IAM service account
2. To verify if the *Controller deployment* is running or not, please use the below command.
   ```
   kubectl get deployment -n kube-system aws-load-balancer-controller
   ```
3. To verify if the *IAM service account* is successfully created or not, please check the status of the latest *CloudFormation Stack* in that region.
   1. The stack status should be `CREATE_COMPLETE`.
   2. The stack output should contains a `ROLE` key which is the **ARN**.

## INGRESS
### PREREQUISITES
Before deploying any **Ingress**, we need to verify a few things.
* Kubernetes Deployment
* Kubernetes Service

1. Check if customer has sucessfully deployed their [**Service**](https://kubernetes.io/docs/concepts/services-networking/service/).
   ```
   kubectl get service -n <NAMESPACE>
   ```
2. Ensure that **Service** type is `NodePort`.
   ```
   kubectl describe service <SERVICE_NAME>
   ```

#### SERVICE
There are 2 basic ways that we can deploy a **Service**:
* Using YAML definition file
* Using Kubernetes CLI

Here is an example of using YAML definition file:
```
apiVersion: v1
kind: Service
metadata:
  name: web-service
  namespace: front-end
spec:
  type: NodePort
  ports:
    - port: 80
      targetPort: 8080
  selector:
    nodegroup-type: front-end-workload
```

Here is an example of using [**Kubernetes CLI**](https://kubernetes.io/docs/tasks/access-application-cluster/service-access-application-cluster/) to expose the application deployment:
```
kubectl expose deployment <DEPLOYMENT_NAME> --type=NodePort --name=<SERVICE_NAME> --port 80
```

### DEPLOYMENT
Here are our existing files.
| File Name | Load Balancer Type | SSL |
| --------- | ------------------ | --- |
| ingress_internet_facing.yaml | Internet Facing | No |
| ingress_internet_facing_ssl.yaml | Internet Facing | Yes |

1. To apply the configuration, please use the below command.
   ```
   kubectl apply -f <FILE_NAME>.yaml
   ```
2. To verify if the ingress is successfully deployed, please use the below commands.
   ```
   kubectl get ingress -n <NAMESPACE>
   kubectl describe ingress <INGRESS_NAME> -n <NAMESPACE>
   ```
3. We should observe a DNS domain with the format `.elb.amazonaws.com` under `ADDRESS` column.
   ```
   NAME          CLASS    HOSTS             ADDRESS                                                                        PORTS   AGE
   ingress-ssl   <none>   hello-world.com   k8s-default-helloworld-1a23b12345-123456789.ap-southeast-1.elb.amazonaws.com   80      1d
   ```

### ANNOTATIONS
Based on our **Ingress** definition, here are some **annotations** that we have to define to meet the requirements.
| Annotations | Allowed Value | Default Value |
| ----------- | ------------- | ------------- |
| kubernetes.io/ingress.class | alb | alb |
| alb.ingress.kubernetes.io/tags | *stringMap* of tags | N/A |
| alb.ingress.kubernetes.io/scheme | `internet-facing` or `internal` | `internal` |
| alb.ingress.kubernetes.io/subnets | *stringList* of subnets' ID | N/A |
| alb.ingress.kubernetes.io/certificate-arn | Retrieve **ARN** of [ACM certificate](https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-describe.html) | N/A |
| alb.ingress.kubernetes.io/ssl-policy | List of valid [Security Policies](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies) | `ELBSecurityPolicy-2016-08` |
| alb.ingress.kubernetes.io/wafv2-acl-arn | Retrieve **ARN** of [WAF ACLs](https://docs.aws.amazon.com/waf/latest/developerguide/web-acl-working-with.html) | N/A |