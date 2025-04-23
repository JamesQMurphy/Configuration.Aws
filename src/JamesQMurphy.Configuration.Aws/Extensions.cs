using Amazon.SimpleSystemsManagement;
using JamesQMurphy.Configuration.Aws;

namespace Microsoft.Extensions.Configuration
{
    public static class Extensions
    {
        public static IConfigurationBuilder AddSsmParameterStore(
            this IConfigurationBuilder configuration,
            string BasePath = "/",
            AmazonSimpleSystemsManagementClient? client = null)
        {
            configuration.Add(new SsmParameterStoreConfigurationSource(BasePath, client ?? new AmazonSimpleSystemsManagementClient()));
            return configuration;
        }
    }
}
