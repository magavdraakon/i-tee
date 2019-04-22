class AssistantsController < ApplicationController
  #restricted to admins
  before_action :authorise_as_admin
  before_action :set_assistant, only: [:show, :edit, :update, :destroy]
  before_action :admin_tab
  respond_to :html, :json

  def index
    @assistants = Assistant.all
    respond_with(@assistants)
  end

  def show
    respond_with(@assistant)
  end

  def new
    @assistant = Assistant.new
    respond_with(@assistant)
  end

  def edit
  end

  def create
    @assistant = Assistant.new(assistant_params)
    @assistant.save
    respond_with(@assistant)
  end

  def update
    @assistant.update_attributes(assistant_params)
    respond_with(@assistant)
  end

  def destroy
    @assistant.destroy
    respond_with(@assistant)
  end

  private # -------------------------------------------------------------

  def set_assistant
    @assistant = Assistant.where(id:params[:id]).first
    unless @assistant
      redirect_to(assistants_path,:notice=>'invalid id.')
    end
  end

  def assistant_params
     params.require(:assistant).permit(:id, :uri, :enabled, :name, :version)
  end
end
