using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Azure.Identity;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;

namespace AKSWebApp.Pages;

public class StorageModel : PageModel
{
    private readonly ILogger<StorageModel> _logger;

    private readonly IConfiguration _configuration;

    public StorageModel(ILogger<StorageModel> logger, IConfiguration configuration)
    {
        _logger = logger;
        _configuration = configuration;
    }

    public string? PageTitleSuffix { get; private set; }
    public List<string>? Blobs { get; private set; }
    public string? StorageAccountName { get; private set; }
    public string? BlobContainer { get; private set; }

    public void OnGet()
    {
        PageTitleSuffix = _configuration["ASPNETCORE_ENVIRONMENT"];
    }

    public async Task<IActionResult> OnPostGetBlobsAsync(string storageAccountName, string blobContainer)
    {
        PageTitleSuffix = _configuration["ASPNETCORE_ENVIRONMENT"];
        
        if (ModelState.IsValid)
        {
            try
            {
                BlobContainerClient containerClient = new(
                new Uri($"https://{storageAccountName}.blob.core.windows.net/{blobContainer}"),
                new DefaultAzureCredential());

                var blobs = new List<string>();

                var retrievedBlobs = containerClient.GetBlobs();

                foreach (var blob in retrievedBlobs)
                {
                    blobs.Add(blob.Name);
                }

                Blobs = blobs;
            }
            catch (Exception ex)
            {
                ModelState.AddModelError("error", "Failed to retrieve blobs: " + ex.Message);
            }
        }

        return Page();
    }
}