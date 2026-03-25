package main

import (
	"os"

	awscdk "github.com/aws/aws-cdk-go/awscdk/v2"
	awsec2 "github.com/aws/aws-cdk-go/awscdk/v2/awsec2"
	_jsii_ "github.com/aws/jsii-runtime-go"
	cdkec2servicemodule "github.com/Bh-an/cdk-ec2-service-module-go/cdkec2servicemodule"
)

type ServiceStackProps struct {
	awscdk.StackProps
	DockerImage *string
}

func NewServiceStack(app awscdk.App, id string, props *ServiceStackProps) awscdk.Stack {
	stack := awscdk.NewStack(app, _jsii_.String(id), &props.StackProps)

	vpc := awsec2.NewVpc(stack, _jsii_.String("ServiceVpc"), &awsec2.VpcProps{
		IpAddresses: awsec2.IpAddresses_Cidr(_jsii_.String("10.30.0.0/16")),
		MaxAzs:      _jsii_.Number(1),
		NatGateways: _jsii_.Number(0),
		SubnetConfiguration: &[]*awsec2.SubnetConfiguration{
			{
				CidrMask:   _jsii_.Number(24),
				Name:       _jsii_.String("Public"),
				SubnetType: awsec2.SubnetType_PUBLIC,
			},
		},
	})

	service := cdkec2servicemodule.NewEc2DockerService(stack, _jsii_.String("PublicApi"), &cdkec2servicemodule.Ec2DockerServiceProps{
		DockerImage: props.DockerImage,
		Infrastructure: &cdkec2servicemodule.ServiceInfrastructureProps{
			SubnetSelection: &awsec2.SubnetSelection{
				SubnetType: awsec2.SubnetType_PUBLIC,
			},
			Vpc: vpc,
			SharedTags: &map[string]*string{
				"Environment": _jsii_.String("service-dev"),
				"ManagedBy":   _jsii_.String("CDK"),
				"Platform":    _jsii_.String("platform"),
				"ServiceRepo": _jsii_.String("ec2-go-service"),
			},
		},
		ServiceName: _jsii_.String("ec2-go-service"),
	})

	awscdk.NewCfnOutput(stack, _jsii_.String("ApiEndpoint"), &awscdk.CfnOutputProps{
		Value: service.ServiceOutputs().Endpoint,
	})

	return stack
}

func main() {
	defer _jsii_.Close()

	app := awscdk.NewApp(nil)
	image := os.Getenv("DOCKER_IMAGE")
	if image == "" {
		image = "ec2-go-service:latest"
	}

	NewServiceStack(app, "Ec2GoServiceStack", &ServiceStackProps{
		DockerImage: _jsii_.String(image),
	})

	app.Synth(nil)
}
