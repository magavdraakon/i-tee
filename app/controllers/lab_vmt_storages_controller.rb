class LabVmtStoragesController < ApplicationController
  before_action :authorise_as_admin
  before_action :admin_tab
  before_action :set_lab_vmt_storage, only: [:show, :edit, :update, :destroy]

  # GET /lab_vmt_storages
  # GET /lab_vmt_storages.json
  def index
    @lab_vmt_storages = LabVmtStorage.all
  end

  # GET /lab_vmt_storages/1
  # GET /lab_vmt_storages/1.json
  def show
  end

  # GET /lab_vmt_storages/new
  def new
    @lab_vmt_storage = LabVmtStorage.new
  end

  # GET /lab_vmt_storages/1/edit
  def edit
  end

  # POST /lab_vmt_storages
  # POST /lab_vmt_storages.json
  def create
    @lab_vmt_storage = LabVmtStorage.new(lab_vmt_storage_params)

    respond_to do |format|
      if @lab_vmt_storage.save
        format.html { redirect_to @lab_vmt_storage, notice: 'Lab vmt storage was successfully created.' }
        format.json { render :show, status: :created, location: @lab_vmt_storage }
      else
        format.html { render :new }
        format.json { render json: @lab_vmt_storage.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /lab_vmt_storages/1
  # PATCH/PUT /lab_vmt_storages/1.json
  def update
    respond_to do |format|
      if @lab_vmt_storage.update(lab_vmt_storage_params)
        format.html { redirect_to @lab_vmt_storage, notice: 'Lab vmt storage was successfully updated.' }
        format.json { render :show, status: :ok, location: @lab_vmt_storage }
      else
        format.html { render :edit }
        format.json { render json: @lab_vmt_storage.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /lab_vmt_storages/1
  # DELETE /lab_vmt_storages/1.json
  def destroy
    @lab_vmt_storage.destroy
    respond_to do |format|
      format.html { redirect_to lab_vmt_storages_url, notice: 'Lab vmt storage was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_lab_vmt_storage
      @lab_vmt_storage = LabVmtStorage.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def lab_vmt_storage_params
      params.require(:lab_vmt_storage).permit(:lab_vmt_id, :storage_id, :controller, :port, :device, :mount)
    end
end
