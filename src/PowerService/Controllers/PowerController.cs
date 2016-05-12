using Microsoft.AspNet.Hosting;
using Microsoft.AspNet.Mvc;

namespace PowerService.Controllers
{
    [Route("api/[controller]")]
    public class PowerController : Controller
    {
        private readonly IHostingEnvironment _hostingEnvironment;

        public PowerController(IHostingEnvironment hostingEnvironment)
        {
            _hostingEnvironment = hostingEnvironment;
        }

        [HttpGet]
        public ActionResult Get()
        {
            var content = System.IO.File.ReadAllText(_hostingEnvironment.MapPath("scripts/app.js"));

            return Content(content, "application/javascript");
        }
    }
}