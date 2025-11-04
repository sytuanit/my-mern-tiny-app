import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';

export interface InfrastructureStackProps extends cdk.StackProps {
  namePrefix: string;
  environment: string;
  localstackEndpoint: string;
}

export class InfrastructureStack extends cdk.Stack {
  public readonly vpc: ec2.Vpc;
  public readonly securityGroup: ec2.SecurityGroup;
  public readonly instanceProfile: iam.InstanceProfile;

  constructor(scope: Construct, id: string, props: InfrastructureStackProps) {
    super(scope, id, {
      ...props,
      // Use LegacyStackSynthesizer for LocalStack to avoid bootstrap requirement
      synthesizer: new cdk.LegacyStackSynthesizer(),
    });

    const { namePrefix, environment, localstackEndpoint } = props;

    // VPC
    this.vpc = new ec2.Vpc(this, 'VPC', {
      ipAddresses: ec2.IpAddresses.cidr('10.0.0.0/16'),
      maxAzs: 1,
      natGateways: 0, // No NAT gateway for LocalStack
      subnetConfiguration: [
        {
          name: 'public',
          subnetType: ec2.SubnetType.PUBLIC,
          cidrMask: 24,
        },
      ],
    });

    // Internet Gateway (automatically attached by VPC)

    // Security Group
    this.securityGroup = new ec2.SecurityGroup(this, 'AppSecurityGroup', {
      vpc: this.vpc,
      description: 'Security group for my-tiny-app EC2 instance',
      allowAllOutbound: true,
    });

    // HTTP - App
    this.securityGroup.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(3000),
      'App HTTP'
    );

    // HTTP - Consumer
    this.securityGroup.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(3001),
      'Consumer HTTP'
    );

    // HTTP - UI
    this.securityGroup.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(3002),
      'UI HTTP'
    );

    // SSH
    this.securityGroup.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(22),
      'SSH'
    );

    // MongoDB
    this.securityGroup.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(27017),
      'MongoDB'
    );

    // Kafka
    this.securityGroup.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(9092),
      'Kafka'
    );

    this.securityGroup.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(9093),
      'Kafka Internal'
    );

    // Zookeeper
    this.securityGroup.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(2181),
      'Zookeeper'
    );

    // IAM Role for EC2
    const role = new iam.Role(this, 'EC2Role', {
      assumedBy: new iam.ServicePrincipal('ec2.amazonaws.com'),
      description: 'IAM role for my-tiny-app EC2 instance',
    });

    // Add policies
    role.addManagedPolicy(
      iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonSSMManagedInstanceCore')
    );

    // Instance Profile
    this.instanceProfile = new iam.InstanceProfile(this, 'EC2InstanceProfile', {
      role,
      instanceProfileName: `${namePrefix}my-tiny-app-instance-profile`,
    });

    // Add tags
    cdk.Tags.of(this.vpc).add('Name', `${namePrefix}my-tiny-app-vpc`);
    cdk.Tags.of(this.vpc).add('Environment', environment);
    cdk.Tags.of(this.securityGroup).add('Name', `${namePrefix}my-tiny-app-sg`);
    cdk.Tags.of(this.securityGroup).add('Environment', environment);

    // Outputs
    new cdk.CfnOutput(this, 'VpcId', {
      value: this.vpc.vpcId,
      description: 'VPC ID',
    });

    new cdk.CfnOutput(this, 'SubnetId', {
      value: this.vpc.publicSubnets[0].subnetId,
      description: 'Public Subnet ID',
    });

    new cdk.CfnOutput(this, 'SecurityGroupId', {
      value: this.securityGroup.securityGroupId,
      description: 'Security Group ID',
    });

    new cdk.CfnOutput(this, 'InstanceProfileName', {
      value: this.instanceProfile.instanceProfileName,
      description: 'IAM Instance Profile Name',
    });
  }
}
