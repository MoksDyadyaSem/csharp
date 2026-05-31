using ExamApi.Models;

namespace ExamApi.Store;

public class BookStore
{
    private readonly List<Author> _authors = new();
    private readonly List<Book> _books = new();
    private int _nextAuthorId = 1;
    private int _nextBookId = 1;

    public BookStore()
    {
        _authors.Add(new Author { Id = 1, Name = "Толстой" });
        _books.Add(new Book { Id = 1, Title = "Война и мир", AuthorId = 1 });
        _nextAuthorId = 2;
        _nextBookId = 2;
    }

    public List<Author> GetAuthors()
    {
        return _authors;
    }

    public Author? GetAuthor(int id)
    {
        foreach (var author in _authors)
        {
            if (author.Id == id)
            {
                return author;
            }
        }

        return null;
    }

    public Author AddAuthor(string name)
    {
        var author = new Author
        {
            Id = _nextAuthorId,
            Name = name
        };
        _nextAuthorId++;
        _authors.Add(author);
        return author;
    }

    public List<Book> GetBooks(int? authorId)
    {
        if (authorId == null)
        {
            return _books;
        }

        var result = new List<Book>();
        foreach (var book in _books)
        {
            if (book.AuthorId == authorId.Value)
            {
                result.Add(book);
            }
        }

        return result;
    }

    public Book? GetBook(int id)
    {
        foreach (var book in _books)
        {
            if (book.Id == id)
            {
                return book;
            }
        }

        return null;
    }

    public Book? AddBook(string title, int authorId)
    {
        if (GetAuthor(authorId) == null)
        {
            return null;
        }

        var book = new Book
        {
            Id = _nextBookId,
            Title = title,
            AuthorId = authorId
        };
        _nextBookId++;
        _books.Add(book);
        return book;
    }
}
