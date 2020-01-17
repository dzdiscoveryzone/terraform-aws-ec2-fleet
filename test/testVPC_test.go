package main

import (
	"fmt"
	"strings"
	"testing"

	"github.com/aws/aws-sdk-go/service/ec2"

	teststructure "github.com/gruntwork-io/terratest/modules/test-structure"

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
	tempTestFolder := teststructure.CopyTerraformFolderToTemp(t, rootFolder, terraformFolderRelativeToRoot)

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
			"private_subnet_count": 2,
			"public_subnet_count":  5,
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
	vpc := aws.GetVpcById(t, vpcID, awsRegion)
	t.Run("Check VPC ID", func(t *testing.T) {
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

	// checkIsSubnetPublic checks whether or not a subnet is public and will rule out any private subnet by using the helper function skipPrivateSubnets
	checkIsSubnetPublic(t, subnets, awsRegion)

	vpcTagsInjected := terraformOptions.Vars["default_tags"]
	t.Run("Check VPC tag Name", func(t *testing.T) {
		vpcTagsMap := vpcTagsInjected.(map[string]string)
		if vpcTagName, ok := vpcTagsMap["Environment"]; !ok {
			t.Errorf("vpc tag Environment not configured. got: %v, want: %v\n", vpcTagName, vpc.Name)

			nameTag := fmt.Sprintf("%s-vpc", vpcTagsMap["Environment"])
			if nameTag != vpc.Name {
				t.Errorf("incorrect tag value for Name, got: %v, want: %v\n", nameTag, vpc.Name)
			}
		}
	})
}

func checkIsSubnetPublic(t *testing.T, subnets []aws.Subnet, region string) {
	subnetIds := make([]*string, len(subnets))
	t.Run("Check if subnets are public", func(t *testing.T) {
		for _, subnet := range subnets {
			subnetIds = append(subnetIds, &subnet.Id)
		}
		skipPrivateSubnets(t, subnetIds, region)
	})
}

// getSubnetTags is a helper function which checks if the VPC Subnet is private by looking at the tag Name and whether it container private in it or not. If it does not, it will be skipped.
func skipPrivateSubnets(t *testing.T, subnetIds []*string, region string) {
	t.Helper()

	ec2Client := aws.NewEc2Client(t, region)
	req, resp := ec2Client.DescribeSubnetsRequest(&ec2.DescribeSubnetsInput{SubnetIds: subnetIds})

	err := req.Send()
	if err != nil {
		t.Errorf("err := req.Send() = %v", err)
	}

	for _, subnet := range resp.Subnets {
		for _, tag := range subnet.Tags {
			if *tag.Key == "Name" && !strings.Contains(*tag.Value, "private") {
				subnetIsPublic := aws.IsPublicSubnet(t, *subnet.SubnetId, region)
				if !subnetIsPublic {
					t.Errorf("subnet %s is not public. got: %t, want: %t", *subnet.SubnetId, subnetIsPublic, true)
				}
			}
		}
	}
}
