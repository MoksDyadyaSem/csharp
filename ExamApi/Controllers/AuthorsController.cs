using ExamApi.Models;
using ExamApi.Store;
using Microsoft.AspNetCore.Mvc;

namespace ExamApi.Controllers;

[ApiController]
[Route("api/authors")]
public class AuthorsController : ControllerBase
{
    private readonly BookStore _store;

    public AuthorsController(BookStore store)
    {
        _store = store;
    }

    [HttpGet]
    public ActionResult<List<Author>> GetAll()
    {
        return Ok(_store.GetAuthors());
    }

    [HttpGet("{id}")]
    public ActionResult<Author> GetById(int id)
    {
        var author = _store.GetAuthor(id);
        if (author == null)
        {
            return NotFound();
        }

        return Ok(author);
    }

    [HttpPost]
    public ActionResult<Author> Create([FromBody] CreateAuthorRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
        {
            return BadRequest("Name is required");
        }

        var author = _store.AddAuthor(request.Name.Trim());
        return CreatedAtAction(nameof(GetById), new { id = author.Id }, author);
    }
}
