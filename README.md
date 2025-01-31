[[_TOC_]]

# Logic App Standard Integration Sample

The purpose of this repo is to show an example integration that uses various AIS-components and how to deploy it. The components in this integration are very basic, the point of this sample is to show how we deploy them together


# AVM

This repo uses AVM to deploy azure resources, if you havent checked it out yes, do it [now!](https://github.com/Azure/bicep-registry-modules)


Below is an overview of our deployment:

::: mermaid
graph TD
subgraph Integration resources
A[main.bicep] -->|uses shared existing resources|A
A[main.bicep] -->|deploy storage account|B
end
B[LogicAppStandard] -->C
subgraph Monitoring resources
C[MonitorAlert] --> D
D[WorkBook] --> F
G[DashBoard]
end
:::

