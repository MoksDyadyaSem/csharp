using ExamApi.Store;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddSingleton<BookStore>();
builder.Services.AddControllers();
builder.WebHost.UseUrls("http://0.0.0.0:5000");

var app = builder.Build();

app.MapControllers();

app.Run();
