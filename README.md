# vegan-terraform-test
This repo is created to host terraform configuration code required to deploy infrastructure for a microservice written in Java

### In order set up the infrastructure for the microservice in a cost-effective way  with terraform, we need to create or provision the following components:

* VPC (Virtual Private Cloud):This will define the networking environment for the services.
* EC2 Instances:This will host the java microservice.
* MySQL RDS instance:This will serve as a database for the microservice.
* Application Load Balancer (ALB):To distribute incoming traffic.
* AWS WAF (Web Application Firewall): To secure and protect the microservice from common web exploits.
* Auto Scaling Group:To scale EC2 instances based on traffic load.
