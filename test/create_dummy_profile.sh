#!/bin/bash

# 🧹 Clear existing AWS credentials
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN
unset AWS_PROFILE
echo "🧹 Cleared previous AWS environment variables."

# 🛠️ Create a dummy AWS CLI profile with fake credentials
aws configure set aws_access_key_id dummyaccesskey --profile dummy
aws configure set aws_secret_access_key dummysecretkey --profile dummy
aws configure set region us-east-1 --profile dummy
echo "✅ Created dummy AWS profile with fake credentials."

# 🔐 Export the dummy profile for this shell session
export AWS_PROFILE=dummy
echo "✅ Using dummy AWS profile."

# 🧪 Test dummy profile (will fail as expected)
aws sts get-caller-identity || echo "❌ As expected: invalid credentials."

echo "✅ Dummy profile ready. You can now run 'terraform plan' or 'go test -v'."
