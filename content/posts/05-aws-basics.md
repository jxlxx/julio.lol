---
title: AWS Technical Essentials Course Notes
date: "2022-05-23"
description: Some notes I took on a beginners course in AWS.
tldr: Pretty good course IMO. (for absolute beginners).
draft: false
tags: ["aws"]
---

[Link to the course (it's free btw)](https://explore.skillbuilder.aws/learn/course/external/view/elearning/1851/aws-technical-essentials?dt=tile&tile=fdt)

# **Module 1: Introduction to Amazon Web Services**
 
### Overview of AWS infrastructure

- AWS resources are in Availability Zones
- Availability Zones are in Regions
- `us-east-2` is a region
- `us-east-2a` is an availability zone
- Services are deployed at either a Global, Region, or AZ level
- Some service require you choose an AZ

### IAM

- When you create an account with email and password that’s called a **root user**
- Email/password combo is one set of credentials but you get another set of credentials called **access keys**, they allow you to use CLI or AWS SDKs
- Access keys have two parts: **access key ID** and **secret access key**
- IAM is global and not specific to regions

### Demo

- Every AWS resource must live inside of a network
- AWS provides a default VPC, virtual private network

# **Module 2: AWS Compute**

AMI: Amazon Machine Image

When selecting an instance type and size, you see: `t3.medium` or `a1.large`

- `t3` and `a1` is the instance family/type + generation, determines the hardware capabilities
- `medium` and `large` is the instance size (vCPUS, memory, etc)
- you only get charged while in the running state, of in the stopping (preparing to hibernate)


[Wild Rydes Web Application](https://webapp.serverlessworkshops.io/)

[AWS Serverless Whitepaper](https://d1.awsstatic.com/whitepapers/architecture/AWS-Serverless-Applications-Lens.pdf)

# **Module 3: AWS Networking**

- In AWS, the smallest IP range you can have is /28, which provides 16 IP addresses. The largest IP range you can have is a /16, which provides 65,536 IP addresses.

To create a VPC, we need to set 2 things:

- region
- IP range

VPC are split into subnets, and then you put your AWS resources into these subnets.

To provide more control over access of resources.

To create a Subnet, we need 3 things:

- the VPC it will live in
- the AZ it will live in
- IP range (subset of the VPC)

VPCs need Internet Gateways (IGW) to connect to the internet.

If you only want traffic from a specific place, for example an on-premises datacenter, then you can create Virtual Private Gateway (VGW).

**AWS reserves 5 IP addresses in each subnet.** 

- 10.0.0.0: Network address.
= 10.0.0.1: Reserved for the VPC router.
- 10.0.0.2: The IP address of the DNS server is the base of the VPC network range plus two. 
- 10.0.0.3: Reserved for future use. (?)
- 10.0.0.255: Network broadcast address. AWS does not support broadcast in a VPC, so they reserve this address.

**How does traffic get routed through the VPC?**

When you create a VPC, AWS creates a route table called the **main route table**.

A route table contains a set of rules, called routes, that are used to determine where traffic is directed.

Default configuration allows traffic between all the subnets in the local network.

**Network Access Control List (Network ACL)** can be thought of as a firewall at the subnet level. 

You can use it to only allow HTTPS traffic in and out of your subnet. Remember if you make a rule to only allow HTTPS traffic in, you have to also make a rule to allow HTTPS traffic out.

A **NAT Gateway** provides internet connectivity to instances and private subnets. A NAT gateway is a **Network Address Translation** service. You can use a NAT gateway to so that instances in a private subnet can connect to services outside your subnet.

The next layer of security is a **Security Group**. This is a firewall at the EC2 level. Security groups are not optional. The default configuration of a new security group blocks all inbound traffic and allows all outbound traffic. This ok and works because security groups will remember if a connection if originally initiated by the EC2 instance or outside and will temporarily allow traffic to respond with modifying the inbound rules.

# **Module 4: AWS Storage**

AWS storage services are grouped into 3 categories: **block storage, file storage, and object storage.**


**File storage**: It's what it sounds like, it’s a file system. Each file has metadata like file name, file size, created date, etc. And files have paths. File storage is good when 
you require centralized access to file that need to be easily shared and managed by multiple host computers.

**Block storage**: splits of data into block, considers each block it’s own thing
- good for things that gets updated a lot because you will only need to update individual blocks not the whole thing


**Object storage**: considers each object its own thing.
    - WORM: write once, read many

**EBS, elastic block storage**  , is like an external drive. Persistent storage.
- EC2 instance storage in the machines drives, but are not saved when the instance is terminated.
- Snapshots are saved from EBS as backups.
- Unlike EBS, which requires a EC2 instance to be used, Amazon S3 is a standalone storage solution.

**S3** is object storage. 
- S3 objects are stored in a flat structure using unique identifiers for look up.
- In S3, you store objects in buckets. This is mandatory.
- At minimum, you need to specify 2 details: the region and the bucket name.
- Bucket names must be unique across all AWS accounts (like in the world).
- Everything in Amazon S3 is private by default (can. only be viewed by the AWS account that created that resource).
- Two ways to change/have more control over this: IAM policies & S3 bucket policies
    - You can specify in IAM policies what users are allowed to do to buckets
    - Or, you can specify on the bucket side what’s allowed to happen to that bucket
- Amazon S3 reinforces encryption in transit (as it travels to and from Amazon S3) and at rest
- You can use S3 versioning. Default behaviour is that objects get overwritten when they get sent to S3.
- There are 6 different S3 storage classes that are optimized for different things.

You can automate automatic tier transitions with **object life cycle** management. You can choose:
- Transition actions: when objects should transition to another storage class
- Expiration actions: when objects expire and should be permanently deleted

# **Module 5: Databases**

nothing of note

# **Module 6: Monitoring, Optimization, and Serverless**

- load balancing: distributing tasks across a set of resources
- you can run a load balancer on an EC2 instance or use ELB
- ELB makes health checks to services to determine whether it should send traffic their way
- ELB is actually really scalable even if it looks like it isn’t

Application Load Balancer — Layer 7: HTTP/HTTPS

Network Load Balancer — Layer 4: TCP/UDP/TLS

Gateway Load Balancer — Layer 3+4: IP

- The ALB is made up of 3 components: rules, listeners, and target groups
    - target group: the backend servers are defined in one or more target groups. This where traffic is directed. You must define a health check for each target group.
    - listener: the client connects to the listener. To  define a listener you must provide a port and a protocol. There can be many listener for a single LB. Ex. listen to port 80 for http traffic.
    - rule: conditions that map clients to target groups

You can have internal or external load balancers. For use within your network or internet facing.

ALB makes routing decisions based on the HTTP protocol, like the URL path (/upload) and host, HTTP headers and method, and the source IP address of the client.

**ALB uses sticky sessions.** If requests must be sent to the same backend server because the application is stateful, use the sticky session feature. This feature uses an HTTP cookie to remember across connections which server to send the traffic to.

NLBs do not understand what an HTTP request is.

NLBs use a flow hash routing algorithm. The algorithm is based on:

- protocol
- source ip and port
- destination ip and port
- TCP sequence number

If all those params are the same, it goes to the same target