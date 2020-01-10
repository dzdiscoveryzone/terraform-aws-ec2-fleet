package main

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestEC2(t *testing.T) {
	approvedRegions := []string{"us-east-1"}
	awsRegion := aws.GetRandomRegion(t, approvedRegions, nil)

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../dev",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"region":    awsRegion,
			"ec2_count": 2,
			"default_tags": map[string]string{
				"Environment":   "dev",
				"Is Production": "No",
			},
		},

		// Environment variables to set when running Terraform
		EnvVars: map[string]string{},
	}

	// At the end of the test, run `terraform destroy`
	defer terraform.Destroy(t, terraformOptions)

	// Run `terraform init` and `terraform apply`
	terraform.InitAndApply(t, terraformOptions)

	instanceID := terraform.Output(t, terraformOptions, "ec2_instance_id")
	tagsReturned := aws.GetTagsForEc2Instance(t, awsRegion, instanceID)
	t.Log(tagsReturned)
	t.Log(tagsReturned["Environment"])

	t.Run("verify ec2 tags", func(t *testing.T) {
		if ec2Tag, ok := tagsReturned["Environment"]; !ok {
			t.Errorf("ec2 tag for environment is not configured. got: %v, want: %v", ec2Tag, terraformOptions.Vars["Environment"])
			t.Run("validate instance Environment tag", func(t *testing.T) {
				if instanceID != ec2Tag {
					t.Errorf("Environment tag is incorrect. got: %v, want: %v", ec2Tag, tagsReturned["Environment"])
				}
			})
		}
	})
	// TODO: Check for correct AMI ID
	//ami := aws.GetEc2InstanceIdsByTag(t, "", "", "")
	// TODO: Check for correct instance type

	t.Log(terraformOptions)
}
