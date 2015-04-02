class LanguagesController < ApplicationController
  def index
    @languages = Language.all

    @languages = @languages.matches(params[:query_string], [:name, :type, :designed_by]) if params[:query_string].present?

    @languages = @languages.where(name: params[:name]) if params[:name].present?
    @languages = @languages.where(type: params[:type]) if params[:type].present?
    @languages = @languages.where(designed_by: params[:designed_by]) if params[:designed_by].present?
  end

  def show
    @language = Language.find(params[:id])
  end

  def new
  end

  def create
    Language.create(params[:language])

    redirect_to languages_path
  end
end
