package main

import (
	"fmt"
	"testing"

	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"

	"github.com/gruntwork-io/terratest/modules/aws"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestVPC(t *testing.T) {
	t.Parallel()
	approvedRegions := []string{"us-east-1"}
	awsRegion := aws.GetRandomRegion(t, approvedRegions, nil)

	// Root folder where terraform files should be (relative to the test folder)
	rootFolder := ".."

	// Relative path to terraform module being tested from the root folder
	terraformFolderRelativeToRoot := "modules/vpc"

	// Copy the terraform folder to a temp folder
	tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, rootFolder, terraformFolderRelativeToRoot)

	azs := []string{"us-east-1a", "us-east-1b", "us-east-1e"}
	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: tempTestFolder,

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"region":               awsRegion,
			"cidr_block":           "172.24.0.0/16",
			"availability_zones":   azs,
			"has_multiple_subnets": true,
			"private_subnet_count": 0,
			"public_subnet_count":  1,
			"enable_dns_hostnames": true,
			"default_tags": map[string]string{
				"Environment":   "dev",
				"Is Production": "No",
			},
		},
	}

	// At the end of the test, run `terraform destroy`
	defer terraform.Destroy(t, terraformOptions)
	// Run `terraform init` and `terraform apply`
	terraform.InitAndApply(t, terraformOptions)

	vpcID := terraform.Output(t, terraformOptions, "vpc_id")
	vpcRegion := (terraformOptions.Vars["region"]).(string)

	vpc := aws.GetVpcById(t, vpcID, vpcRegion)
	t.Run("Correct VPC ID", func(t *testing.T) {
		if vpc.Id != vpcID {
			t.Errorf("VPC ID incorrect. got: %v, want: %v\n", vpc.Id, vpcID)
		}
	})

	subnets := aws.GetSubnetsForVpc(t, vpcID, awsRegion)
	t.Run("Less than 1 subnet", func(t *testing.T) {
		if len(subnets) < 1 {
			t.Errorf("no subnets deployed, got: %v", len(subnets))
		}
	})

	// TODO: Check to see if a subnet is public or private, possibly based off tags?

	t.Run("Check if subnets are public", func(t *testing.T) {
		for _, subnet := range subnets {
			subnetIsPublic := aws.IsPublicSubnet(t, subnet.Id, awsRegion)
			if !subnetIsPublic {
				t.Errorf("subnet %s is not public. got: %t, want: %t", subnet.Id, subnetIsPublic, true)
			}
		}
	})

	vpcTagsInjected := terraformOptions.Vars["default_tags"]
	t.Run("Check VPC tag Name", func(t *testing.T) {
		vpcTagsMap := vpcTagsInjected.(map[string]string)
		if vpcTagName, ok := vpcTagsMap["Environment"]; !ok {
			t.Errorf("vpc tag Environment not configured. got: %v, want: %v\n", vpcTagName, vpc.Name)

			nameTag := fmt.Sprintf("%s-vpc", vpcTagsMap["Environment"])
			if nameTag != vpc.Name {
				t.Errorf("incorrect tag value for Name, got: %v, want: %v\n", vpcTagName, vpc.Name)
			}
		}
	})
}
