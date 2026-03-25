package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"

	cdkec2servicemodule "github.com/Bh-an/sc-cdk-ec2-service-module-go/cdkec2servicemodule"
	awscdk "github.com/aws/aws-cdk-go/awscdk/v2"
	awsec2 "github.com/aws/aws-cdk-go/awscdk/v2/awsec2"
	_jsii_ "github.com/aws/jsii-runtime-go"
)

type serviceStackProps struct {
	awscdk.StackProps
	dockerImage *string
}

type vpcConfig struct {
	Cidr           string `json:"cidr"`
	MaxAzs         int    `json:"maxAzs"`
	NatGateways    int    `json:"natGateways"`
	SubnetName     string `json:"subnetName"`
	SubnetType     string `json:"subnetType"`
	SubnetCidrMask int    `json:"subnetCidrMask"`
}

type environmentConfig struct {
	StackName           string            `json:"stackName"`
	Region              string            `json:"region"`
	Platform            string            `json:"platform"`
	Environment         string            `json:"environment"`
	ServiceName         string            `json:"serviceName"`
	SharedTags          map[string]string `json:"sharedTags"`
	Vpc                 vpcConfig         `json:"vpc"`
	SubnetSelectionType string            `json:"subnetSelectionType"`
}

func mustLoadConfig() *environmentConfig {
	deployEnv := os.Getenv("DEPLOY_ENV")
	if deployEnv == "" {
		deployEnv = "dev"
	}

	configPath := filepath.Join("environments", fmt.Sprintf("%s.json", deployEnv))
	content, err := os.ReadFile(configPath)
	if err != nil {
		panic(fmt.Errorf("failed to read %s: %w", configPath, err))
	}

	var cfg environmentConfig
	if err := json.Unmarshal(content, &cfg); err != nil {
		panic(fmt.Errorf("failed to parse %s: %w", configPath, err))
	}

	required := map[string]string{
		"stackName":   cfg.StackName,
		"region":      cfg.Region,
		"platform":    cfg.Platform,
		"environment": cfg.Environment,
		"serviceName": cfg.ServiceName,
	}
	for fieldName, value := range required {
		if value == "" {
			panic(fmt.Errorf("%s is required in %s", fieldName, configPath))
		}
	}

	return &cfg
}

func toSubnetType(value string) awsec2.SubnetType {
	switch value {
	case "PUBLIC":
		return awsec2.SubnetType_PUBLIC
	case "PRIVATE_WITH_EGRESS":
		return awsec2.SubnetType_PRIVATE_WITH_EGRESS
	case "PRIVATE_ISOLATED":
		return awsec2.SubnetType_PRIVATE_ISOLATED
	default:
		return awsec2.SubnetType_PUBLIC
	}
}

func resolveSharedTags(cfg *environmentConfig) *map[string]*string {
	tags := map[string]*string{
		"Environment": _jsii_.String(cfg.Environment),
		"Platform":    _jsii_.String(cfg.Platform),
		"ServiceRepo": _jsii_.String("sc-ec2-go-service"),
	}

	for key, value := range cfg.SharedTags {
		tags[key] = _jsii_.String(value)
	}

	return &tags
}

func newServiceStack(app awscdk.App, cfg *environmentConfig, props *serviceStackProps) awscdk.Stack {
	stack := awscdk.NewStack(app, _jsii_.String(cfg.StackName), &props.StackProps)

	vpc := awsec2.NewVpc(stack, _jsii_.String("ServiceVpc"), &awsec2.VpcProps{
		IpAddresses: awsec2.IpAddresses_Cidr(_jsii_.String(cfg.Vpc.Cidr)),
		MaxAzs:      _jsii_.Number(float64(cfg.Vpc.MaxAzs)),
		NatGateways: _jsii_.Number(float64(cfg.Vpc.NatGateways)),
		SubnetConfiguration: &[]*awsec2.SubnetConfiguration{
			{
				CidrMask:   _jsii_.Number(float64(cfg.Vpc.SubnetCidrMask)),
				Name:       _jsii_.String(cfg.Vpc.SubnetName),
				SubnetType: toSubnetType(cfg.Vpc.SubnetType),
			},
		},
	})

	service := cdkec2servicemodule.NewEc2DockerService(stack, _jsii_.String("Service"), &cdkec2servicemodule.Ec2DockerServiceProps{
		DockerImage: props.dockerImage,
		Infrastructure: &cdkec2servicemodule.ServiceInfrastructureProps{
			Vpc: vpc,
			SubnetSelection: &awsec2.SubnetSelection{
				SubnetType: toSubnetType(cfg.SubnetSelectionType),
			},
			SharedTags: resolveSharedTags(cfg),
		},
		ServiceName: _jsii_.String(cfg.ServiceName),
	})

	awscdk.NewCfnOutput(stack, _jsii_.String("ServiceEndpoint"), &awscdk.CfnOutputProps{
		Value: service.ServiceOutputs().Endpoint,
	})

	return stack
}

func main() {
	defer _jsii_.Close()

	cfg := mustLoadConfig()
	image := os.Getenv("DOCKER_IMAGE")
	if image == "" {
		image = "ghcr.io/bh-an/ec2-go-service:latest"
	}

	app := awscdk.NewApp(nil)
	newServiceStack(app, cfg, &serviceStackProps{
		StackProps: awscdk.StackProps{
			Env: &awscdk.Environment{
				Region: _jsii_.String(cfg.Region),
			},
		},
		dockerImage: _jsii_.String(image),
	})

	app.Synth(nil)
}
