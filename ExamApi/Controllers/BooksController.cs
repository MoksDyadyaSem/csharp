using ExamApi.Models;
using ExamApi.Store;
using Microsoft.AspNetCore.Mvc;

namespace ExamApi.Controllers;

[ApiController]
[Route("api/books")]
public class BooksController : ControllerBase
{
    private readonly BookStore _store;

    public BooksController(BookStore store)
    {
        _store = store;
    }

    [HttpGet]
    public ActionResult<List<Book>> GetAll([FromQuery] int? authorId)
    {
        return Ok(_store.GetBooks(authorId));
    }

    [HttpGet("{id}")]
    public ActionResult<Book> GetById(int id)
    {
        var book = _store.GetBook(id);
        if (book == null)
        {
            return NotFound();
        }

        return Ok(book);
    }

    [HttpPost]
    public ActionResult<Book> Create([FromBody] CreateBookRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Title))
        {
            return BadRequest("Title is required");
        }

        var book = _store.AddBook(request.Title.Trim(), request.AuthorId);
        if (book == null)
        {
            return BadRequest("Author not found");
        }

        return CreatedAtAction(nameof(GetById), new { id = book.Id }, book);
    }
}
