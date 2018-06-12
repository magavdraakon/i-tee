class LabBadgesController < ApplicationController
  #restricted to admins 
  before_action :authorise_as_admin
  before_action :admin_tab
  before_action :set_badge, only: [:show, :edit, :update, :destroy]

  # GET /lab_badges
  # GET /lab_badges.json
  def index
    @lab_badges = LabBadge.all
    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @lab_badges }
    end
  end

  # GET /lab_badges/1
  # GET /lab_badges/1.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @lab_badge }
    end
  end

  # GET /lab_badges/new
  # GET /lab_badges/new.json
  def new
    @lab_badge = LabBadge.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @lab_badge }
    end
  end

  # GET /lab_badges/1/edit
  def edit
  end

  # POST /lab_badges
  # POST /lab_badges.json
  def create
    @lab_badge = LabBadge.new(lab_badge_params)

    respond_to do |format|
      if @lab_badge.save
        format.html { redirect_to @lab_badge, :notice => 'Lab badge was successfully created.' }
        format.json { render :json => @lab_badge, :status => :created, :location => @lab_badge }
      else
        format.html { render :action => 'new' }
        format.json { render :json => @lab_badge.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lab_badges/1
  # PUT /lab_badges/1.json
  def update
    respond_to do |format|
      if @lab_badge.update_attributes(lab_badge_params)
        format.html { redirect_to @lab_badge, :notice => 'Lab badge was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render :action => 'edit' }
        format.json { render :json => @lab_badge.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lab_badges/1
  # DELETE /lab_badges/1.json
  def destroy
    @lab_badge.destroy

    respond_to do |format|
      format.html { redirect_to lab_badges_url }
      format.json { head :ok }
    end
  end

  private # -------------------------------------------------------
  def set_badge
    @lab_badge = LabBadge.where(id: params[:id]).first
    unless @lab_badge
      redirect_to(lab_badges_path,:notice=>'invalid id.')
    end
  end

  def lab_badge_params
    params.require(:lab_badge).permit(:id, :lab_id, :badge_id, :name, :description)
  end
end
