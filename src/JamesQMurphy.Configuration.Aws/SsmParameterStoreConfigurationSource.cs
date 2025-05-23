﻿using Amazon.SimpleSystemsManagement;
using Microsoft.Extensions.Configuration;
using System;

namespace JamesQMurphy.Configuration.Aws;

public class SsmParameterStoreConfigurationSource : IConfigurationSource
{
    public string BasePath { get; }
    public AmazonSimpleSystemsManagementClient AmazonSimpleSystemsManagementClient { get; }
    public SsmParameterStoreConfigurationSource(string basePath, AmazonSimpleSystemsManagementClient amazonSimpleSystemsManagementClient)
    {
        if (basePath is null)
        {
            throw new ArgumentNullException(nameof(basePath));
        }
        if (basePath.EndsWith(SsmParameterStoreConfigurationProvider.KeyDelimiter))
        {
            BasePath = basePath;
        }
        else
        {
            BasePath = basePath + SsmParameterStoreConfigurationProvider.KeyDelimiter;
        }
        AmazonSimpleSystemsManagementClient = amazonSimpleSystemsManagementClient ?? throw new ArgumentNullException(nameof(amazonSimpleSystemsManagementClient));
    }

    public IConfigurationProvider Build(IConfigurationBuilder builder)
    {
        return new SsmParameterStoreConfigurationProvider(this);
    }
}
