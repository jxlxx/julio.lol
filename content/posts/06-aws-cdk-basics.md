---
title: AWS CDK Basics
date: "2022-07-20"
description: Talking notes for an AWS CDK workshop.
draft: false
tags: ["aws", "devops"]
---

# What is CDK?

Cloud Development Kit.

Imagine… You are running some kind of software business.

You’re most likely not self-hosting, and instead using some kind of cloud provider.

Something like: AWS, GCP, Digital Ocean, Linode… etc.

What are the kinds of services you need? 

| Domain Name          | Route53                  |
| -------------------- | ------------------------ |
| SSL                  | Certificate Manager      |
| CDN                  | CloudFront               |
| Static Assets, etc   | S3                       |
| Database             | RDS, Dynamo, Aurora, etc |
| Authentication       | Cognito                  |
| REST API             | API Gateway              |
| Business Logic Stuff | Lambda, EC2              |
| Container management | ECR                      |

You also probably want a Dev, Stag, and Prod stack.

So a CDK is code that you write, which generates CloudFormation Templates (JSON or YAML), which you push to AWS CloudFormation, and then that builds your AWS infrastructure.

And CloudFormation Templates are ANNOYING. 
 

# How to start a CDK project

Get the code: `git checkout v1`

Every CDK app should be in its own directory.

For this tutorial, all my code is in `/BackendGuild`. So I did:

```bash
mkdir CDKWorkshop
```

CDK apps can be written in a bunch of languages:

- typescript
- javascript
- python
- java
- C#
- Go

I went with typescript because it has types, everyone can understand it, and it has the most examples and documentation out of all the languages listed by a huuuuge margin. 

Globally install `aws-cdk` and `typescript` with `npm`. You also need the `aws-cli`.

```tsx
cdk init app --language typescript
```

# Project Structure

```bash
lib/name-stack.ts # where you spend most of your time
                  # where the CDK main stack is defined

bin/name.ts # enypoint of the CDK app
            # loads the stack defined in ^^
            # call stuff in lib and instantiate it

package.json  # npm module manifest, build/run scripts etc

cdk.json      # "toolkit" how to run your app

tsconfig.json # typescript configuration

node_modules/ # project dependencies

```

- 2 directories
- node dependency folder
- a bunch of config files

## A note on the lingo

Everything that the init command just created is called a CDK app.

Inside the app there are “stacks”

Inside the stacks there are “constructs”

# Simple Example

`bin/name.ts`

```tsx
#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { CdkWorkshopStack } from '../lib/cdk-workshop-stack';

const app = new cdk.App();
new CdkWorkshopStack(app, 'CdkWorkshopStack');
```

All this does is load and instantiate the `name` stack.

Who cares. Moving on.

Now let’s look at `lib/name-stack.ts`

```tsx
import * as cdk from 'aws-cdk-lib';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as subs from 'aws-cdk-lib/aws-sns-subscriptions';
import * as sqs from 'aws-cdk-lib/aws-sqs';

export class CdkWorkshopStack extends cdk.Stack {
  constructor(scope: cdk.App, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const queue = new sqs.Queue(this, 'CdkWorkshopQueue', {
      visibilityTimeout: cdk.Duration.seconds(300)
    });

    const topic = new sns.Topic(this, 'CdkWorkshopTopic');

    topic.addSubscription(new subs.SqsSubscription(queue));
  }
}
```

This does three main things:

1. Creates an SQS Queue
2. SNS Topic
3. Subscribes the `1` to receive any messages published to `2`

## `scope` , `id`, and `props`

`scope` is always the first argument in which constructs are created. Usually you just pass in `this`, because you want to define constructs with the current construct.

`id` is the local identity of the construct, a unique way to refer to it with its scope.

`props` are initialization properties. The lambda props accepts properties like `runtime`, `code`, `handler` name.

# Our example: creating an S3 bucket

First of all I had to add a couple environment variables:

- `CDK_DEFAULT_ACCOUNT`
- `CDK_DEFAULT_REGION`

Then I ran `cdk synth` to see if everything looked good.

Then I ran `cdk bootstrap` which creates a “bootstrap stack” for the app.

Now I have a bunch of roles, a bucket, etc.

Finally, I do:

```bash
cdk deploy
```

Now lets add some changes:

```tsx
import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import { aws_s3 as s3 } from 'aws-cdk-lib'

export class CdkWorkshopStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    new s3.Bucket(this, 'MyThirdBucket', {
        versioned: true,
        removalPolicy: cdk.RemovalPolicy.DESTROY,
        autoDeleteObjects: true
    });
  }
}
```

And then run `cdk diff`:

# What else can you do?

Check the docs: [class Bucket (construct) · AWS CDK](https://docs.aws.amazon.com/cdk/api/v2/docs/aws-cdk-lib.aws_s3.Bucket.html)

# Important Commands

`cdk bootstrap`

- This installs a “bootstrap stack” of AWS stuff that will be used to create your stack
- This stack includes resources that are used in the toolkit’s operation
- For example, you can store code in an S3 bucket and use that during the deployment process

`cdk synth` 

- generates the cloudformation templates

`cdk deploy`

- actually deploys to `aws`

`cdk diff`

- if you make changes to the `cdk` this will show you what’s been changes

`cdk deploy --hotswap`

- this will try to update the infrastructure you currently have with any changes you make
- for example if you want to disable versioning for a bucket or change it’s privacy settings

`cdk watch`

- this will watch your code for changes and try to deploy if it can
- but you can only make asset changes
- for example you cannot disable/enable versioning but you can adda picture/data to the contents of the bucket

note: These commands deliberately introduces drift in CloudFormation stacks in order to speed up deployments.

Drift is when you cloud formation templates don’t match your actual stack.

`cdk destroy`

- destroys stuff 💀 

# What is AWS Lambda

AWS Lambda is a serverless, event-driven compute service that lets you run code for virtually any type of application or backend service without provisioning or managing servers. 

What do you need:

- a name
- a trigger
- code (either a script or an executable in a zip)
- a runtime
- (optional) layers

## What is a layer?

A layer is a ZIP archive that contains libraries, a custom runtime, or other dependencies. With layers, you can use libraries in your function without needing to include them in your deployment package.


# Let’s use lambda

Adding an AWS lambda function

1. create a directory `lambda` in the root of the CDK app
2. add a line to `.gitignore` to NOT ignore all the `.js` files in lambda
    
```
!lambda/*
```
    
3. add the following js file, `lambda/hello.js`

```tsx
exports.handler = async function(event) {
  console.log("request:", JSON.stringify(event, undefined, 2));
  return {
    statusCode: 200,
    headers: { "Content-Type": "text/plain" },
    body: `Hello, CDK! You've hit ${event.path}\n`
  };
};
```

This is a lambda function that always returns the text **“Hello, CDK! You’ve hit [url path]”**

To define an AWS Lambda function you need to use the **AWS Construct Library.**

The construct library is divided into modules.

```tsx
import * as cdk from 'aws-cdk-lib';
import * as lambda from 'aws-cdk-lib/aws-lambda';

export class CdkWorkshopStack extends cdk.Stack {
  constructor(scope: cdk.App, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // defines an AWS Lambda resource
    const hello = new lambda.Function(this, 'HelloHandler', {
      runtime: lambda.Runtime.NODEJS_16_X,    // runtime
      code: lambda.Code.fromAsset('lambda'),  // code loaded from our "lambda" directory
      handler: 'hello.handler'                // file is "hello", function is "handler"
    });
  }
}
```

# Testing Lambda

- go to test menu
- select an apigateway-aws-proxy test from the drop down
- hit test

# Using CDK watch

Note: since it is a typescript project and we are using javascript in the lambda function, we have to update `cdk.json` to not exclude the files

# Adding REST trigger

To actually interact with a lambda function from outside of the AWS console you have to give it some kind of trigger.

An obvious example would be, watching for uploads to an S3 bucket.

What we can also do is expose a rest api call that call the lambda function. 

The most sensible way to do that would be to use API Gateway, an AWS service to expose public HTTP endpoints.

```tsx
import * as cdk from 'aws-cdk-lib';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigw from 'aws-cdk-lib/aws-apigateway';

export class CdkWorkshopStack extends cdk.Stack {
  constructor(scope: cdk.App, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // defines an AWS Lambda resource
    const hello = new lambda.Function(this, 'HelloHandler', {
      runtime: lambda.Runtime.NODEJS_14_X,    // execution environment
      code: lambda.Code.fromAsset('lambda'),  // code loaded from "lambda" directory
      handler: 'hello.handler'                // file is "hello", function is "handler"
    });

    // defines an API Gateway REST API resource backed by our "hello" function.
    new apigw.LambdaRestApi(this, 'Endpoint', {
      handler: hello
    });

  }
}
```

# Life Lessons


- GUIs suck (I always knew this actually)
- “use things the way they are intended to be used” - paraphrasing jim
    
    

# Questions & Thoughts

## Terraform vs. CDKs

Disclaimer: i don’t know what I’m talking about.

Terraform uses a JSON-like language to define resources and other data, the HCL, or HashiCorp Configuration Language.

CDKs use code which then generates CloudFormation Templates in Json/yaml.

Terraform works on a lot of platforms, CDK is AWS specific.

Terraform is more reusable. You can “reuse” CDK code but you cannot “create your own modules”.

## Cuelang would be interesting for this kinda thing I THINK

Disclaimer: i don’t know what I’m talking about here either. 

[CUE (Configure Unify Execute)](https://cuelang.org/)

Not a “full” programming language. It’s kinda like Jsonnet.

CUE is written in Go.

> The CUE language has an unusual property which sets it apart from many other languages and formats - types and values are the same. *Not the same as only same type of structure, like JSON and JSON Schema,* ***but actually the same*.**

An aws example I found:

[Take a cue to supercharge your configurations](https://tidycloudaws.com/take-a-cue-to-supercharge-your-configurations/)

Can create reusable definitions.

# Fun Fact

I went to a golang meetup last week and this guy pronounced `fmt` as *fumpt* 😳


