class BadgesController < ApplicationController
  #restricted to admins 
  before_action :authorise_as_admin
  before_action :admin_tab
  before_action :set_badge, only: [:show, :edit, :update, :destroy]

  # GET /badges
  # GET /badges.json
  def index
    @badges = Badge.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @badges }
    end
  end

  # GET /badges/1
  # GET /badges/1.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @badge }
    end
  end

  # GET /badges/new
  # GET /badges/new.json
  def new
    @badge = Badge.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @badge }
    end
  end

  # GET /badges/1/edit
  def edit
  end

  # POST /badges
  # POST /badges.json
  def create
    @badge = Badge.new(badge_params)

    respond_to do |format|
      if @badge.save
        format.html { redirect_to @badge, :notice => 'Badge was successfully created.' }
        format.json { render :json => @badge, :status => :created, :location => @badge }
      else
        format.html { render :action => 'new' }
        format.json { render :json => @badge.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /badges/1
  # PUT /badges/1.json
  def update
    respond_to do |format|
      if @badge.update_attributes(badge_params)
        format.html { redirect_to @badge, :notice => 'Badge was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render :action => 'edit' }
        format.json { render :json => @badge.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /badges/1
  # DELETE /badges/1.json
  def destroy
    @badge.destroy

    respond_to do |format|
      format.html { redirect_to badges_url }
      format.json { head :ok }
    end
  end

  private # ----------------------------
  def set_badge
    @badge = Badge.where(id: params[:id]).first
    unless @badge
      redirect_to(badges_path,:notice=>'invalid id.')
    end
  end

  def badge_params
     params.require(:badge).permit(:id, :icon, :placeholder)
  end
end
