namespace ExamApi.Models;

public class CreateBookRequest
{
    public string Title { get; set; } = string.Empty;
    public int AuthorId { get; set; }
}
