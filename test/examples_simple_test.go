package test_test

import (
	"context"
	"fmt"
	"os"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/kr/pretty"
)

func TestDefaults(t *testing.T) {
	ctx := context.Background()

	// Setup terratest
	rootFolder := "../"
	terraformFolderRelativeToRoot := "examples/simple"

	tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, rootFolder, terraformFolderRelativeToRoot)

	terraformOptions := &terraform.Options{
		TerraformDir: tempTestFolder,
		Upgrade:      true,
		NoColor:      os.Getenv("CI") == "true",
		Vars: map[string]interface{}{
			"namespace": strings.ToLower(random.UniqueID()),
			// The sandbox account already has the singleton GitHub OIDC
			// provider, so exercise the lookup path instead of creating one.
			"create_provider": false,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.DestroyContext(t, ctx, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApplyContext(t, ctx, terraformOptions)

	// Print out the Terraform Output values
	_, _ = pretty.Print(terraform.OutputAllContext(t, ctx, terraformOptions))

	providerArn := terraform.OutputContext(t, ctx, terraformOptions, "oidc_provider_arn")
	if !strings.Contains(providerArn, ":oidc-provider/token.actions.githubusercontent.com") {
		t.Errorf("expected the GitHub OIDC provider ARN, got %q", providerArn)
	}

	roles := terraform.OutputMapOfObjectsContext(t, ctx, terraformOptions, "roles")
	ciRole, ok := roles["ci"].(map[string]interface{})
	if !ok {
		t.Fatalf(
			"expected a 'ci' role in the roles output%s",
			makediff(map[string]interface{}{"ci": "role object"}, roles),
		)
	}
	roleArn, _ := ciRole["arn"].(string)
	if !strings.Contains(roleArn, ":role/") {
		t.Errorf("expected an IAM role ARN for the 'ci' role, got %q", roleArn)
	}

	// AWS Session
	_, err := config.LoadDefaultConfig(
		ctx,
		config.WithRegion("us-east-1"),
	)

	if err != nil {
		t.Fatal(err)
	}
}

func makediff(want interface{}, got interface{}) string {
	s := fmt.Sprintf("\nwant: %# v", pretty.Formatter(want))
	s = fmt.Sprintf("%s\ngot: %# v", s, pretty.Formatter(got))
	diffs := pretty.Diff(want, got)
	s += "\ndifferences: "
	for _, d := range diffs {
		s = fmt.Sprintf("%s\n  - %s", s, d)
	}
	return s
}
