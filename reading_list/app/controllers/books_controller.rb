class BooksController < ApplicationController

  def index
    books = Book.all
    render json: books, each_serializer: BookIndexSerializer
  end

  def show
    book = Book.find(params[:id])
    render json: book
  end

  def create
    book = Book.new(book_params)
    if book.save
      render json: book, status: :created
    else
      render json: book.errors, status: :unprocessable_entity
    end
  end

  private

  def book_params
    params.permit(:title, :author, :description, :cover_image_url)
  end
  
end
