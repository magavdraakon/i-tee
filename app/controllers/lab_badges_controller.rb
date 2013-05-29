class LabBadgesController < ApplicationController
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
    @lab_badge = LabBadge.find(params[:id])

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
    @lab_badge = LabBadge.find(params[:id])
  end

  # POST /lab_badges
  # POST /lab_badges.json
  def create
    @lab_badge = LabBadge.new(params[:lab_badge])

    respond_to do |format|
      if @lab_badge.save
        format.html { redirect_to @lab_badge, :notice => 'Lab badge was successfully created.' }
        format.json { render :json => @lab_badge, :status => :created, :location => @lab_badge }
      else
        format.html { render :action => "new" }
        format.json { render :json => @lab_badge.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lab_badges/1
  # PUT /lab_badges/1.json
  def update
    @lab_badge = LabBadge.find(params[:id])

    respond_to do |format|
      if @lab_badge.update_attributes(params[:lab_badge])
        format.html { redirect_to @lab_badge, :notice => 'Lab badge was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @lab_badge.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lab_badges/1
  # DELETE /lab_badges/1.json
  def destroy
    @lab_badge = LabBadge.find(params[:id])
    @lab_badge.destroy

    respond_to do |format|
      format.html { redirect_to lab_badges_url }
      format.json { head :ok }
    end
  end
end
