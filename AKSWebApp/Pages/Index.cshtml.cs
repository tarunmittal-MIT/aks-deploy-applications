using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

namespace AKSWebApp.Pages;

public class IndexModel : PageModel
{
    private readonly ILogger<IndexModel> _logger;

    private readonly IConfiguration _configuration;

    public IndexModel(ILogger<IndexModel> logger, IConfiguration configuration)
    {
        _logger = logger;
        _configuration = configuration;
    }

    public string? PageTitleSuffix { get; private set; }
    public string? Secret { get; private set; }
    public string? KeyVaultUrl { get; private set; }

    public void OnGet()
    {
        PageTitleSuffix = _configuration["ASPNETCORE_ENVIRONMENT"];
    }
}
