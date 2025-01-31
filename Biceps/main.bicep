// Base Parameters
@description('Required')
@allowed(['dev', 'qa', 'prod'])
param environment string = 'dev'

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('The unique guid for this workbook instance')
param workbookId string = guid('sample-workbook')

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  scope: resourceGroup('rg-ai-shared-${environment}')
  name: 'ai-01-shared-${environment}'
}

resource aspLA 'Microsoft.Web/serverfarms@2022-09-01' existing = {
  scope: resourceGroup('rg-asp-shared-${environment}')
  name: 'plan-01-wf-${environment}'
}

//if you want to change the query just upload it to KQLQueries folder
var query = string(loadTextContent('../KQLQueries/laAlertSample.kusto'))

module laStdStorage 'br/public:avm/res/storage/storage-account:0.16.0' = {
  name: 'la-sto-deploy-${environment}'
  params: {
    name: 'stglasample${environment}'
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
     }
  }
}

module laStd 'br/public:avm/res/web/site:0.13.1' = {
  name: 'la-deploy-${environment}'
  params: {
    name: 'la-sample-${environment}'
    kind: 'functionapp,workflowapp'
    appInsightResourceId: appInsights.id
    serverFarmResourceId: aspLA.id
    storageAccountResourceId: laStdStorage.outputs.resourceId
    httpsOnly: true
    siteConfig: {
      alwaysOn: false
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
    }
    managedIdentities: {
      systemAssigned: true
    }
    appSettingsKeyValuePairs: {
      AzureFunctionsJobHost__logging__logLevel__default: 'Trace'
      FUNCTIONS_EXTENSION_VERSION: '~4'
      FUNCTIONS_WORKER_RUNTIME: 'dotnet'
      AzureFunctionsJobHost__extensionBundle__id: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
      AzureFunctionsJobHost__extensionBundle__version: '[1.*, 2.0.0)'
    }
  }
}

//monitoring
module alertGroup 'br/public:avm/res/insights/action-group:0.4.0' = {
  name: 'alertGroup-deploy-${environment}'
  params: {
    name: 'alertGroup-shared-${environment}'
    groupShortName: 'Ops'
    location: 'global'
    emailReceivers: [
      {
      emailAddress: 'viktor@testingco.com'
      name: 'viktor'
      useCommonAlertSchema: true
      }
    ]
  }
}

module alert 'br/public:avm/res/insights/scheduled-query-rule:0.1.0' = {
  name: 'alert-deploy-${environment}'
  params: {
    // Required parameters
    criterias: {
      allOf: [
        {
          query: query
          timeAggregation: 'Count'
          dimensions: []
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    name:  'alert-shared-${environment}'
    scopes: [
      appInsights.id
    ]
    // Non-required parameters
    evaluationFrequency: 'P1D'
    location: location
    windowSize: 'P1D'
    autoMitigate: false
    actions: [
      alertGroup.outputs.resourceId
    ]
  }
  dependsOn:  [
  ]
}
//doesnt exist in AVM as of now, /cry =(
resource workbook 'Microsoft.Insights/workbooks@2023-06-01' = {
  kind: 'shared'
  location: location
  name: workbookId
  properties: {
    category: 'workbook'
    displayName: 'mywb'
    serializedData: loadTextContent('../GalleryTemplates/gallerytemplate.json') //default is LAstd, change this to your workbook gallery template
    sourceId: appInsights.id
    version: '1.0'
  }
}

// Outputs
output laname string = laStd.outputs.name
output ladefaultHostname string = laStd.outputs.defaultHostname
output laresourceId string = laStd.outputs.resourceId
output laresourceGroupName string = laStd.outputs.resourceGroupName
output lasystemAssignedMIPrincipalId string = laStd.outputs.systemAssignedMIPrincipalId
