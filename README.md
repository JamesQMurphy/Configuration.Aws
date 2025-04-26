# JamesQMurphy.Configuration.Aws

`JamesQMurphy.Configuration.Aws` is a .NET library that integrates with AWS Systems Manager (SSM) Parameter Store to retrieve configuration values and map them into the .NET Configuration system. This package is designed to simplify the process of securely managing application configuration using AWS SSM Parameter Store.

## Features
- Retrieves configuration values from AWS SSM Parameter Store.
- Supports recursive retrieval of parameters.
- Automatically maps AWS SSM parameter names to .NET configuration keys.
- Supports decryption of secure string parameters.

## Installation

Install the package via NuGet:

    dotnet add package JamesQMurphy.Configuration.Aws


## Usage

### Adding the Provider to Your Configuration

This code shows how to add the SSM Parameter Store as a configuration source:

    var builder = WebApplication.CreateBuilder(args);

    builder.Configuration.AddSsmParameterStore("/my-app/config/");

    var app = builder.Build();



### Mapping Parameter Store Keys to .NET Configuration Keys

AWS SSM Parameter Store keys are mapped to .NET configuration keys as follows:
- The `BasePath` is stripped from the beginning of the parameter name.
- The `/` delimiter in AWS SSM keys is replaced with `:` to match the .NET configuration key format.

For example:
- Parameter Store key: `/my-app/config/Database/ConnectionString`
- .NET configuration key: `Database:ConnectionString`

### Accessing Configuration Values

Once the configuration is built, you can access the values as you would with any other .NET configuration source:

    string connectionString = configuration["Database:ConnectionString"];
    Console.WriteLine($"Connection String: {connectionString}");


## Required IAM Permissions

To use this library, the AWS IAM role or user associated with your application must have the following permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParametersByPath"
      ],
      "Resource": "arn:aws:ssm:<region>:<account-id>:parameter/<base-path>/*"
    }
  ]
}
```


Replace `<region>`, `<account-id>`, and `<base-path>` with the appropriate values for your AWS environment.

## Notes
- Ensure that the `BasePath` provided to the `SsmParameterStoreConfigurationSource` matches the prefix of your parameters in the Parameter Store.
- If your parameters include secure strings, the `WithDecryption` option is enabled by default to decrypt them.

## License

This package is licensed under the MIT License.
