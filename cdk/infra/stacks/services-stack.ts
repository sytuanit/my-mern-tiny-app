import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as fs from 'fs';
import * as path from 'path';
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

export class ServicesStack extends cdk.Stack {
  public readonly instance: ec2.Instance;

  constructor(scope: Construct, id: string, props: ServicesStackProps) {
    super(scope, id, {
      ...props,
      // Use LegacyStackSynthesizer for LocalStack to avoid bootstrap requirement
      synthesizer: new cdk.LegacyStackSynthesizer(),
    });

    const {
      namePrefix,
      environment,
      localstackEndpoint,
      infrastructureStack,
      appImageTag = 'latest',
      consumerImageTag = 'latest',
      uiImageTag = 'latest',
    } = props;

    // Default AMI for Amazon Linux 2023
    const ami = ec2.MachineImage.latestAmazonLinux2023({
      cpuType: ec2.AmazonLinuxCpuType.X86_64,
    });

    // User data script
    const userDataScript = this.getUserDataScript({
      dockerRegistry: 'localhost',
      appImageTag,
      consumerImageTag,
      uiImageTag,
      mongodbUri: 'mongodb://mongodb:27017/my-tiny-app',
      kafkaBroker: 'kafka:9093',
      kafkaTopic: 'item-events',
      kafkaGroupId: 'my-tiny-app-consumer-group',
      appApiUrl: `http://localhost:3000`,
      apiUrl: `http://localhost:3000/api`,
      nodeEnv: environment,
      awsRegion: this.region,
      awsEndpointUrl: localstackEndpoint,
      appPort: '3000',
      consumerPort: '3001',
      uiPort: '3002',
    });

    // EC2 Instance
    this.instance = new ec2.Instance(this, 'AppServer', {
      vpc: infrastructureStack.vpc,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PUBLIC,
      },
      instanceType: ec2.InstanceType.of(
        ec2.InstanceClass.T3,
        ec2.InstanceSize.MICRO
      ),
      machineImage: ami,
      securityGroup: infrastructureStack.securityGroup,
      role: infrastructureStack.instanceProfile.role,
      userData: ec2.UserData.custom(userDataScript),
    });

    // Add tags
    cdk.Tags.of(this.instance).add('Name', `${namePrefix}my-tiny-app-server`);
    cdk.Tags.of(this.instance).add('Environment', environment);
    cdk.Tags.of(this.instance).add('Type', 'services');

    // Outputs
    new cdk.CfnOutput(this, 'InstanceId', {
      value: this.instance.instanceId,
      description: 'EC2 Instance ID',
    });

    new cdk.CfnOutput(this, 'PublicIp', {
      value: this.instance.instancePublicIp,
      description: 'EC2 Instance Public IP',
    });

    new cdk.CfnOutput(this, 'PrivateIp', {
      value: this.instance.instancePrivateIp,
      description: 'EC2 Instance Private IP',
    });
  }

  private getUserDataScript(variables: {
    dockerRegistry: string;
    appImageTag: string;
    consumerImageTag: string;
    uiImageTag: string;
    mongodbUri: string;
    kafkaBroker: string;
    kafkaTopic: string;
    kafkaGroupId: string;
    appApiUrl: string;
    apiUrl: string;
    nodeEnv: string;
    awsRegion: string;
    awsEndpointUrl: string;
    appPort: string;
    consumerPort: string;
    uiPort: string;
  }): string {
    // Read user_data.sh template
    // Try multiple paths (for compiled JS and TypeScript)
    const possiblePaths = [
      path.join(__dirname, '../../../../terraform/localstack/modules/services/user_data.sh'),
      path.join(process.cwd(), 'terraform/localstack/modules/services/user_data.sh'),
      path.join(__dirname, '../../../terraform/localstack/modules/services/user_data.sh'),
    ];
    
    let userDataPath: string | null = null;
    for (const p of possiblePaths) {
      if (fs.existsSync(p)) {
        userDataPath = p;
        break;
      }
    }
    
    if (!userDataPath) {
      throw new Error(`User data script not found. Tried: ${possiblePaths.join(', ')}`);
    }

    let userData = fs.readFileSync(userDataPath, 'utf-8');

    // Replace variables in user_data.sh
    userData = userData.replace(/\${docker_registry}/g, variables.dockerRegistry);
    userData = userData.replace(/\${app_image_tag}/g, variables.appImageTag);
    userData = userData.replace(/\${consumer_image_tag}/g, variables.consumerImageTag);
    userData = userData.replace(/\${ui_image_tag}/g, variables.uiImageTag);
    userData = userData.replace(/\${mongodb_uri}/g, variables.mongodbUri);
    userData = userData.replace(/\${kafka_broker}/g, variables.kafkaBroker);
    userData = userData.replace(/\${kafka_topic}/g, variables.kafkaTopic);
    userData = userData.replace(/\${kafka_group_id}/g, variables.kafkaGroupId);
    userData = userData.replace(/\${app_api_url}/g, variables.appApiUrl);
    userData = userData.replace(/\${api_url}/g, variables.apiUrl);
    userData = userData.replace(/\${node_env}/g, variables.nodeEnv);
    userData = userData.replace(/\${aws_region}/g, variables.awsRegion);
    userData = userData.replace(/\${aws_endpoint_url}/g, variables.awsEndpointUrl);
    userData = userData.replace(/\${app_port}/g, variables.appPort);
    userData = userData.replace(/\${consumer_port}/g, variables.consumerPort);
    userData = userData.replace(/\${ui_port}/g, variables.uiPort);

    return userData;
  }
}

