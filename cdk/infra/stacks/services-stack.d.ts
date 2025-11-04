import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import { Construct } from 'constructs';
import { InfrastructureStack } from './infrastructure-stack';
export interface ServicesStackProps extends cdk.StackProps {
    namePrefix: string;
    environment: string;
    localstackEndpoint: string;
    infrastructureStack: InfrastructureStack;
    appImageTag?: string;
    consumerImageTag?: string;
    uiImageTag?: string;
}
export declare class ServicesStack extends cdk.Stack {
    readonly instance: ec2.Instance;
    constructor(scope: Construct, id: string, props: ServicesStackProps);
    private getUserDataScript;
}
