class StoragesController < ApplicationController
  before_action :authorise_as_admin
  before_action :admin_tab
  before_action :set_storage, only: [:show, :edit, :update, :destroy]

  # GET /storages
  # GET /storages.json
  def index
    @storages = Storage.all
    @storage = (params[:id] ? Storage.find(params[:id]) : Storage.new)
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @storages }
    end
  end

  # GET /storages/1
  # GET /storages/1.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @storage }
    end
  end

  # GET /storages/new
  def new
    @storage = Storage.new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @storage }
    end
  end

  # GET /storages/1/edit
  def edit
  end

  # POST /storages
  # POST /storages.json
  def create
    @storage = Storage.new(storage_params)

    respond_to do |format|
      if @storage.save
        format.html { redirect_to storages_url, notice: 'Storage was successfully created.' }
        format.json { render :show, status: :created, location: @storage }
      else
         @storages = Storage.all
        format.html { render :index }
        format.json { render json: @storage.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /storages/1
  # PATCH/PUT /storages/1.json
  def update
    respond_to do |format|
      if @storage.update(storage_params)
        format.html { redirect_to storages_url, notice: 'Storage was successfully updated.' }
        format.json { render :show, status: :ok, location: @storage }
      else
         @storages = Storage.all
        format.html { render :index }
        format.json { render json: @storage.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /storages/1
  # DELETE /storages/1.json
  def destroy
    @storage.destroy
    respond_to do |format|
      format.html { redirect_to storages_url, notice: 'Storage was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_storage
      @storage = Storage.where(id: params[:id]).first
      unless @storage
        redirect_to(storages_path,:notice=>'invalid id.')
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def storage_params
      params.require(:storage).permit(:storage_type, :path, :enabled)
    end
end
