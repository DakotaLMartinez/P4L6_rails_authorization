# Phase 4, Lecture 4 - Rails Serializers Exercises

## Reading List Application Features
- When we display the books list, we can display an Add Book button to users who haven't added the book to their reading list and a Remove Book button to users who have already added it.
- When we visit the Book show page, we can also display a list of the book's readers.

Do the following:
- create a `BookIndex` and `Book` serializer. 
- The `BookIndex` will display a list of books with just the attributes that you choose
- The `BookShow` will display those attributes and also the readers of the book

Test your work in Postman or the browser and then if you like, try to boot up this [react client](https://github.com/DakotaLMartinez/reading_list_client) and see if it works!