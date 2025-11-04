import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';
export interface InfrastructureStackProps extends cdk.StackProps {
    namePrefix: string;
    environment: string;
    localstackEndpoint: string;
}
export declare class InfrastructureStack extends cdk.Stack {
    readonly vpc: ec2.Vpc;
    readonly securityGroup: ec2.SecurityGroup;
    readonly instanceProfile: iam.InstanceProfile;
    constructor(scope: Construct, id: string, props: InfrastructureStackProps);
}
