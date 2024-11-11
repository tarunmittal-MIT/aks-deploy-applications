resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: 'cr${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  sku: {
    name: 'Basic'
  }
}
