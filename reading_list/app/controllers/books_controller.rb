class BooksController < ApplicationController
  before_action :confirm_authentication
  before_action :set_book, only: [:show, :update, :destroy]
  before_action :authorize_user, only: [:update, :destroy]

  def index
    books = Book.all
    render json: books, each_serializer: BookIndexSerializer
  end

  def show
    render json: @book
  end

  def create
    book = Book.new(book_params)
    if book.save
      render json: book, status: :created
    else
      render json: book.errors, status: :unprocessable_entity
    end
  end

  def update
    if @book.update(book_params)
      render json: @book, status: :ok, serializer: BookShowSerializer
    else
      render json: book.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @book.destroy
    head :no_content
  end

  private

  def book_params
    params.permit(:title, :author, :description, :cover_image_url)
  end

  def set_book
    @book = Book.find(params[:id])
  end

  def authorize_user
    user_can_modify = current_user.admin?
    if !user_can_modify
      render json: { error: "You don't have permission to perform this action" }, status: :forbidden 
    end
  end

  
end
