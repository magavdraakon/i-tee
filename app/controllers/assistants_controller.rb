class AssistantsController < ApplicationController
  #restricted to admins
  before_filter :authorise_as_admin
  before_filter :set_assistant, only: [:show, :edit, :update, :destroy]
   before_filter :admin_tab
  respond_to :html

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
    @assistant = Assistant.new(params[:assistant])
    @assistant.save
    respond_with(@assistant)
  end

  def update
    @assistant.update_attributes(params[:assistant])
    respond_with(@assistant)
  end

  def destroy
    @assistant.destroy
    respond_with(@assistant)
  end

  private
    def set_assistant
      @assistant = Assistant.find(params[:id])
    end
end
