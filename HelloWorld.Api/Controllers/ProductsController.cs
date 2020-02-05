using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using HelloWorld.Api.Controllers.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace HelloWorld.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ProductsController : ControllerBase
    {
        private readonly ILogger<ProductsController> _logger;
        public ProductsController(ILogger<ProductsController> logger)
        {
            _logger = logger;
        }

        [HttpGet]
        public IEnumerable<Product> Get()
        {
            var random = new Random();
            var products = Enumerable.Range(1, 10).Select(index => new Product
            {
                Id = Guid.NewGuid().ToString(),
                Name = $"Product {random.Next(1, 1000)}"
            }).ToArray();
            _logger.LogInformation($"Send {products.Length} products");
            return products;

        }
    }
}