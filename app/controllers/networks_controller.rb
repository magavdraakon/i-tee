class NetworksController < ApplicationController
  before_action :authorise_as_admin
  before_action :admin_tab
  before_action :set_network, :only=>[:show, :edit, :update, :destroy]

  # GET /networks
  # GET /networks.json
  def index
    @networks = Network.all
    @network = (params[:id] ? Network.find(params[:id]) : Network.new)
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @networks }
    end
  end

  # GET /networks/1
  # GET /networks/1.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @network }
    end
  end

  # GET /networks/new
  # GET /networks/new.json
  def new
    @network = Network.new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @network }
    end
  end

  # GET /networks/1/edit
  def edit
  end

  # POST /networks
  # POST /networks.json
  def create
    @network = Network.new(network_params)
    respond_to do |format|
      if @network.save
        format.html { redirect_to networks_path, notice: 'Network was successfully created.' }
        format.json { render json: @network, status: :created, location: @network }
      else
        format.html { render action: 'new' }
        format.json { render json: @network.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /networks/1
  # PUT /networks/1.json
  def update
    respond_to do |format|
      if @network.update_attributes(network_params)
        format.html { redirect_to networks_path, notice: 'Network was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: 'edit' }
        format.json { render json: @network.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /networks/1
  # DELETE /networks/1.json
  def destroy
    @network.destroy
    respond_to do |format|
      format.html { redirect_to networks_url }
      format.json { head :ok }
    end
  end

private # -------------------------------------------------------
  def set_network
    @network = Network.where(id: params[:id]).first
    unless @network
      redirect_to(networks_path,:notice=>'invalid id.')
    end
  end

  def network_params
    params.require(:network).permit(:id, :name, :net_type)
  end
end
