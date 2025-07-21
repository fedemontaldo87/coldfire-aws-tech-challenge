package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestInfrastructurePlan(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		NoColor:      true,
	}

	planOutput := terraform.InitAndPlan(t, terraformOptions)

	t.Log("📄 Terraform plan output:\n", planOutput)

	// Verifica que se planean los recursos clave
	assert.Contains(t, planOutput, "aws_vpc")
	assert.Contains(t, planOutput, "aws_instance")             // EC2
	assert.Contains(t, planOutput, "aws_autoscaling_group")    // ASG
	assert.Contains(t, planOutput, "aws_lb")                   // ALB
	assert.Contains(t, planOutput, "aws_s3_bucket")            // S3 buckets
    assert.Contains(t, planOutput, "aws_iam_role")             // IAM roles - commented for test
}