using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using HelloWorld.Web.Models;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace HelloWorld.Web.Pages
{
    public class IndexModel : PageModel
    {
        private readonly ILogger<IndexModel> _logger;
        private readonly HttpClient _httpClient;
        private readonly string _apiUrl;

        public IList<Product> Products { get; set; } = new List<Product>();
        public string ErrorMessage { get; set; }
        public bool SuccessfulRequest { get { return string.IsNullOrEmpty(ErrorMessage); } }

        public IndexModel(ILogger<IndexModel> logger, IHttpClientFactory httpClientFactory, IConfiguration configuration)
        {
            _logger = logger;
            _httpClient = httpClientFactory.CreateClient();
            _apiUrl = configuration.GetSection("HELLOWORLD_APIURL").Value;
        }

        public async Task OnGet()
        {
            Products = await GetProductsAsync();
        }

        private async Task<IList<Product>> GetProductsAsync()
        {
            if (string.IsNullOrEmpty(_apiUrl))
            {
                ErrorMessage = $"API ulr address is not found in environment variable";
                _logger.LogError($"ERROR: {ErrorMessage}");
                return new List<Product>();
            }
            try
            {
                _logger.LogInformation($"Request products data from {_apiUrl}");
                var result = await _httpClient.GetAsync(_apiUrl);
                if (result.IsSuccessStatusCode)
                {
                    ErrorMessage = "";
                    var products = JsonConvert.DeserializeObject<IList<Product>>(await result.Content.ReadAsStringAsync());
                    _logger.LogInformation($"Received {products.Count} products");
                    return products;
                }
                else
                {
                    ErrorMessage = $"Unsuccessful status code: {result.StatusCode}";
                    _logger.LogError($"ERROR: {ErrorMessage}");
                    return new List<Product>();
                }
            }
            catch (Exception ex)
            {
                ErrorMessage = ex.Message;
                _logger.LogError($"ERROR: {ErrorMessage}");
                return new List<Product>();
            }
        }
    }
}
