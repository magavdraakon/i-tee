class LabVmtNetworksController < ApplicationController
  before_filter :authorise_as_admin
  before_filter :admin_tab
  before_filter :set_lab_vmt_network, only: [:show, :edit, :update, :destroy]


  # GET /lab_vmt_networks
  # GET /lab_vmt_networks.json
  def index
    @lab_vmt_networks = LabVmtNetwork.all
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @lab_vmt_networks }
    end
  end

  # GET /lab_vmt_networks/1
  # GET /lab_vmt_networks/1.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @lab_vmt_network }
    end
  end

  # GET /lab_vmt_networks/new
  # GET /lab_vmt_networks/new.json
  def new
    @lab_vmt_network = LabVmtNetwork.new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @lab_vmt_network }
    end
  end

  # GET /lab_vmt_networks/1/edit
  def edit
  end

  # POST /lab_vmt_networks
  # POST /lab_vmt_networks.json
  def create
    @lab_vmt_network = LabVmtNetwork.new(lab_vmt_network_params)
    respond_to do |format|
      if @lab_vmt_network.save
        format.html { redirect_to @lab_vmt_network, notice: 'Lab vmt network was successfully created.' }
        format.json { render json: @lab_vmt_network, status: :created, location: @lab_vmt_network }
      else
        format.html { render action: 'new' }
        format.json { render json: @lab_vmt_network.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /lab_vmt_networks/1
  # PUT /lab_vmt_networks/1.json
  def update
    respond_to do |format|
      if @lab_vmt_network.update_attributes(lab_vmt_network_params)
        format.html { redirect_to @lab_vmt_network, notice: 'Lab vmt network was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: 'edit' }
        format.json { render json: @lab_vmt_network.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /lab_vmt_networks/1
  # DELETE /lab_vmt_networks/1.json
  def destroy
    @lab_vmt_network.destroy
    respond_to do |format|
      format.html { redirect_to lab_vmt_networks_url }
      format.json { head :ok }
    end
  end

  private # -------------------------------------------------------
  def set_lab_vmt_network
    @lab_vmt_network = LabVmtNetwork.where(id: params[:id]).first
    unless @lab_vmt_network
      redirect_to(lab_vmt_networks_path,:notice=>'invalid id.')
    end
  end

  def lab_vmt_network_params
    params.require(:lab_vmt_network).permit(:id, :network_id, :slot, :lab_vmt_id, :promiscuous, :reinit_mac, :ip)
  end
end
