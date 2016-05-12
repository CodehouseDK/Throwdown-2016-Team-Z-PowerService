using System.Collections.Generic;
using Microsoft.AspNet.Mvc;

namespace PowerService.Controllers
{
    [Route("api/[controller]")]
    public class PsuController : Controller
    {
        [HttpGet]
        public IEnumerable<string> Get()
        {
            return new[] {"value1", "value2"};
        }
    }
}