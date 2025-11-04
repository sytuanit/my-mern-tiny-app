# AWS CDK Infrastructure for my-tiny-app (LocalStack)

CDK project để provision infrastructure và services lên LocalStack EC2.

## 📁 Cấu trúc

```
cdk/
├── infra/
│   ├── app.ts                    # CDK App entry point
│   └── stacks/
│       ├── infrastructure-stack.ts  # VPC, Security Groups, IAM
│       └── services-stack.ts        # EC2 Instance với Docker containers
├── package.json
├── tsconfig.json
└── cdk.json
```

## 🏗️ Architecture

Giống như Terraform version:
- **InfrastructureStack**: VPC, Security Groups, IAM (deploy một lần)
- **ServicesStack**: EC2 Instance với Docker containers (deploy khi code thay đổi)

## 🚀 Setup

### 1. Install Dependencies

```bash
cd cdk
npm install
```

### 2. Install AWS CDK CLI (nếu chưa có)

```bash
npm install -g aws-cdk
```

### 3. Bootstrap CDK (chỉ cần một lần cho LocalStack)

```bash
# Set LocalStack endpoint
$env:AWS_REGION = "us-east-1"
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "test"
$env:LOCALSTACK_ENDPOINT = "http://localhost:4567"

# Bootstrap CDK for LocalStack
cdk bootstrap --app "npx ts-node infra/app.ts"
```

## 📝 Configuration

### Environment Variables

Set environment variables trước khi deploy:

```powershell
$env:ENVIRONMENT = "dev"  # hoặc "stg"
$env:AWS_REGION = "us-east-1"
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "test"
$env:LOCALSTACK_ENDPOINT = "http://localhost:4567"
```

### Image Tags

Set image tags khi deploy services:

```powershell
$env:APP_IMAGE_TAG = "dev-abc123"
$env:CONSUMER_IMAGE_TAG = "dev-abc123"
$env:UI_IMAGE_TAG = "dev-abc123"
```

Hoặc pass qua CDK context:

```bash
cdk deploy ServicesStack --context appImageTag=dev-abc123
```

## 🚀 Deploy

### 1. Deploy Infrastructure (Một lần)

```powershell
# Set environment
$env:ENVIRONMENT = "dev"
$env:AWS_REGION = "us-east-1"
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "test"
$env:LOCALSTACK_ENDPOINT = "http://localhost:4567"

# Deploy
cd cdk
npm run deploy:infra
```

### 2. Deploy Services (Khi code thay đổi)

```powershell
# Set environment và image tags
$env:ENVIRONMENT = "dev"
$env:APP_IMAGE_TAG = "dev-$(git rev-parse --short HEAD)"
$env:CONSUMER_IMAGE_TAG = "dev-$(git rev-parse --short HEAD)"
$env:UI_IMAGE_TAG = "dev-$(git rev-parse --short HEAD)"
$env:AWS_REGION = "us-east-1"
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "test"
$env:LOCALSTACK_ENDPOINT = "http://localhost:4567"

# Deploy
cd cdk
npm run deploy:services
```

### 3. Deploy All

```powershell
cdk deploy --all --app "npx ts-node infra/app.ts"
```

## 🔍 Verify

```powershell
# List stacks
cdk list --app "npx ts-node infra/app.ts"

# Diff changes
cdk diff InfrastructureStack --app "npx ts-node infra/app.ts"
cdk diff ServicesStack --app "npx ts-node infra/app.ts"

# Synthesize CloudFormation template
cdk synth InfrastructureStack --app "npx ts-node infra/app.ts"
```

## 🗑️ Destroy

```powershell
# Destroy all
cdk destroy --all --app "npx ts-node infra/app.ts"

# Destroy specific stack
cdk destroy InfrastructureStack --app "npx ts-node infra/app.ts"
cdk destroy ServicesStack --app "npx ts-node infra/app.ts"
```

## 📚 CDK Commands

```bash
npm run build          # Compile TypeScript
npm run watch          # Watch for changes
npm run cdk            # CDK CLI
npm run deploy:infra   # Deploy infrastructure
npm run deploy:services # Deploy services
npm run destroy        # Destroy all
```

## 🔄 Migration from Terraform

CDK này tương đương với Terraform structure:
- `terraform/localstack/modules/infrastructure` → `cdk/infra/stacks/infrastructure-stack.ts`
- `terraform/localstack/modules/services` → `cdk/infra/stacks/services-stack.ts`

## ⚠️ LocalStack Configuration

CDK cần được configure để point đến LocalStack:

```typescript
// In app.ts
const cdkEnv: cdk.Environment = {
  account: '000000000000',  // LocalStack dummy account
  region: 'us-east-1',
};
```

Và set AWS CLI/CDK để dùng LocalStack endpoint:

```powershell
$env:AWS_ENDPOINT_URL = "http://localhost:4567"
```

## 📝 Notes

- CDK sẽ generate CloudFormation templates và deploy lên LocalStack
- User data script được read từ `terraform/localstack/modules/services/user_data.sh`
- Image tags có thể pass qua environment variables hoặc CDK context

