class GroupsController < ApplicationController
  def index
    render json: Group.all, each_serializer: GroupIndexSerializer
  end

  def show
    group = Group.find(params[:id])
    render json: group
  end

  def create
    group = Group.new(group_params)
    if group.save
      render json: group, status: :created
    else
      render json: group.errors, status: :unprocessable_entity
    end
  end

  private

  def group_params
    params.permit(:name, :location)
  end

end
