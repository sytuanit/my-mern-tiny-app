#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { InfrastructureStack } from './stacks/infrastructure-stack';
import { ServicesStack } from './stacks/services-stack';

const app = new cdk.App();

// Environment configuration
const env = process.env.ENVIRONMENT || 'dev';
const namePrefix = env === 'dev' ? 'dev-' : 'stg-';
const awsRegion = process.env.AWS_REGION || 'us-east-1';
const localstackEndpoint = process.env.LOCALSTACK_ENDPOINT || 'http://localhost:4567';

// CDK environment for LocalStack
const cdkEnv: cdk.Environment = {
  account: '000000000000',
  region: awsRegion,
};

// Infrastructure Stack (VPC, Security Groups, IAM)
const infraStack = new InfrastructureStack(app, 'InfrastructureStack', {
  env: cdkEnv,
  namePrefix,
  environment: env,
  localstackEndpoint,
  description: 'Infrastructure stack for my-tiny-app (VPC, Security Groups, IAM)',
});

// Services Stack (EC2 Instance with Docker containers)
const servicesStack = new ServicesStack(app, 'ServicesStack', {
  env: cdkEnv,
  namePrefix,
  environment: env,
  localstackEndpoint,
  infrastructureStack: infraStack,
  appImageTag: process.env.APP_IMAGE_TAG,
  consumerImageTag: process.env.CONSUMER_IMAGE_TAG,
  uiImageTag: process.env.UI_IMAGE_TAG,
  description: 'Services stack for my-tiny-app (EC2 with Docker containers)',
});

// Add dependency
servicesStack.addDependency(infraStack);

app.synth();

