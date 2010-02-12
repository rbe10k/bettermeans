class RetrosController < ApplicationController
  before_filter :find_retro, :only => [:show]
  before_filter :find_project, :only => [:index, :index_json, :dashdata, :new, :edit, :create, :update, :destroy, :show_multiple]  
  before_filter :authorize

  # GET /retros
  # GET /retros.xml
  def index
    @retros = Retro.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @retros }
    end
  end
  
  def index_json
    render :json => Retro.find(:all, :conditions => {:project_id => @project.id}).to_json
    # render :json => Retro.all.to_json
  end
  
  def dashdata
    render :json => Issue.find(:all, :conditions => {:retro_id => params[:id]}).to_json(:include => {:journals => {:include => :user}, :issue_votes => {:include => :user}, :status => {:only => :name}, :todos => {:only => [:id, :subject, :completed_on]}, :tracker => {:only => [:name,:id]}, :author => {:only => [:firstname, :lastname, :login]}, :assigned_to => {:only => [:firstname, :lastname, :login]}})
  end
  

  # GET /retros/1
  # GET /retros/1.xml
  def show
    @retro = Retro.find(params[:id])
    @issue = @retro.issues.first
    @user_hash = {}
    @team_hash = {}
    @final_hash = {}
    @issue.issue_votes.each do |issue_vote|
      next if issue_vote.vote_type != IssueVote::JOIN_VOTE_TYPE
      if issue_vote.user_id == @issue.assigned_to_id
        @user_hash.store issue_vote.user_id, 100
      else
        @user_hash.store issue_vote.user_id, 0
      end
    end
    logger.info(@user_hash.inspect)
    @retro.retro_ratings.each do |retro_rating|
      @user_hash[retro_rating.ratee_id] = retro_rating.score.round if retro_rating.rater_id == User.current.id
      @team_hash[retro_rating.ratee_id] = retro_rating.score.round if retro_rating.rater_id == -1
      @final_hash[retro_rating.ratee_id] = retro_rating.score.round if retro_rating.rater_id == -2
    end
    
    # @user_retro_hash = {}
    # 
    # new_user_retro = {"issues" => [], "total_points" => 0, "percentage_points" => 0, "journals" => [], "total_journals" => 0, "votes" => [], "total_votes" => 0}
    # 
    # # @issue_group = Issue.find(:all,:include => :assigned_to, :conditions => {:retro_id => @retro.id}).group_by{|issue| issue.assigned_to_id}
    # issue_group = @retro.issues.group_by{|issue| issue.assigned_to_id}
    # 
    # #Calculating oustanding points for entire retrospective
    # @total_points = 0
    # issue_group.each_value {|issues| @total_points += issues.collect(&:points).sum }
    # 
    # @max_range = 0
    # @pie_data_points = []
    # @pie_labels_points = []
    # @max_points = 0
    # #Adding users that have issues assigned to them and calculating total points for each user
    # issue_group.keys.sort.each do |assigned_to_id|
    #   @user_retro_hash.store assigned_to_id, new_user_retro.dup unless @user_retro_hash.has_key? assigned_to_id
    #   @user_retro_hash[assigned_to_id].store "issues", issue_group[assigned_to_id]
    #   @user_retro_hash[assigned_to_id].store "total_points", issue_group[assigned_to_id].collect(&:points).sum 
    #   @user_retro_hash[assigned_to_id].store "percentage_points", (@user_retro_hash[assigned_to_id]["total_points"].to_f / @total_points * 100).round_to(1).to_i
    #   @max_points = @user_retro_hash[assigned_to_id]["total_points"] if @user_retro_hash[assigned_to_id]["total_points"] > @max_points
    #   @pie_data_points << @user_retro_hash[assigned_to_id]["percentage_points"]
    #   @pie_labels_points << User.find(assigned_to_id).login + " #{@user_retro_hash[assigned_to_id]["percentage_points"].to_s}%"
    # end
    # 
    # @max_range = @max_points if @max_points > @max_range
    #         
    # #Total journals
    # @total_journals = @retro.journals.count
    # @pie_data_journals = []
    # @pie_labels_journals = []
    # @max_journals = 0
    # journals_group = @retro.journals.group_by{|journal| journal.user_id}
    # journals_group.keys.sort.each do |user_id|
    #   @user_retro_hash.store user_id, new_user_retro.dup unless @user_retro_hash.has_key? user_id
    #   @user_retro_hash[user_id].store "journals", journals_group[user_id]
    #   @user_retro_hash[user_id].store "total_journals", journals_group[user_id].length
    #   @user_retro_hash[user_id].store "percentage_journals", (@user_retro_hash[user_id]["total_journals"].to_f / @total_journals * 100).round_to(1).to_i
    #   @max_journals = @user_retro_hash[user_id]["total_journals"] if @user_retro_hash[user_id]["total_journals"] > @max_journals
    #   @pie_data_journals << @user_retro_hash[user_id]["percentage_journals"]
    #   @pie_labels_journals << User.find(user_id).login + " #{@user_retro_hash[user_id]["percentage_journals"].to_s}%"
    # end
    # 
    # @max_range = @max_journals if @max_journals > @max_range
    # 
    # 
    # #Total voting activity
    # @total_votes = @retro.issue_votes.count
    # @pie_data_votes = []
    # @pie_labels_votes = []
    # @max_votes = 0
    # votes_group = @retro.issue_votes.group_by{|issue_vote| issue_vote.user_id}
    # votes_group.keys.sort.each do |user_id|
    #   @user_retro_hash.store user_id, new_user_retro.dup unless @user_retro_hash.has_key? user_id
    #   @user_retro_hash[user_id].store "votes", votes_group[user_id]
    #   @user_retro_hash[user_id].store "total_votes", votes_group[user_id].length
    #   @user_retro_hash[user_id].store "percentage_votes", (@user_retro_hash[user_id]["total_votes"].to_f / @total_votes * 100).round_to(1).to_i
    #   @max_votes = @user_retro_hash[user_id]["total_votes"] if @user_retro_hash[user_id]["total_votes"] > @max_votes
    #   @pie_data_votes << @user_retro_hash[user_id]["percentage_votes"]
    #   @pie_labels_votes << User.find(user_id).login + " #{@user_retro_hash[user_id]["percentage_votes"].to_s}%"
    # end
    # 
    # @max_range = @max_votes if @max_votes > @max_range
    # 
    # #Build Chart
    # @point_totals = []
    # @vote_totals = []
    # @journal_totals = []
    # @axis_labels = []
    # x_axis = ''
    # 
    # @user_retro_hash.keys.sort.each do |user_id|
    #   @point_totals << @user_retro_hash[user_id]["total_points"]
    #   @vote_totals << @user_retro_hash[user_id]["total_votes"]
    #   @journal_totals << @user_retro_hash[user_id]["total_journals"]
    #   x_axis = x_axis + User.find(user_id).login + '|'
    # end
    # @axis_labels << x_axis
    # 
    # #Average time taken to complete a point?
        

    respond_to do |format|
      format.html { render :layout => 'blank'}# show.html.erb
      format.xml  { render :xml => @retro }
    end
  end

  def show_multiple
    @retro = Retro.find(params[:id])
    @user_retro_hash = {}
    
    new_user_retro = {"issues" => [], "total_points" => 0, "percentage_points" => 0, "journals" => [], "total_journals" => 0, "votes" => [], "total_votes" => 0}
    
    # @issue_group = Issue.find(:all,:include => :assigned_to, :conditions => {:retro_id => @retro.id}).group_by{|issue| issue.assigned_to_id}
    issue_group = @retro.issues.group_by{|issue| issue.assigned_to_id}
    
    #Calculating oustanding points for entire retrospective
    @total_points = 0
    issue_group.each_value {|issues| @total_points += issues.collect(&:points).sum }

    @max_range = 0
    @pie_data_points = []
    @pie_labels_points = []
    @max_points = 0
    #Adding users that have issues assigned to them and calculating total points for each user
    issue_group.keys.sort.each do |assigned_to_id|
      @user_retro_hash.store assigned_to_id, new_user_retro.dup unless @user_retro_hash.has_key? assigned_to_id
      @user_retro_hash[assigned_to_id].store "issues", issue_group[assigned_to_id]
      @user_retro_hash[assigned_to_id].store "total_points", issue_group[assigned_to_id].collect(&:points).sum 
      @user_retro_hash[assigned_to_id].store "percentage_points", (@user_retro_hash[assigned_to_id]["total_points"].to_f / @total_points * 100).round_to(1).to_i
      @max_points = @user_retro_hash[assigned_to_id]["total_points"] if @user_retro_hash[assigned_to_id]["total_points"] > @max_points
      @pie_data_points << @user_retro_hash[assigned_to_id]["percentage_points"]
      @pie_labels_points << User.find(assigned_to_id).login + " #{@user_retro_hash[assigned_to_id]["percentage_points"].to_s}%"
    end
    
    @max_range = @max_points if @max_points > @max_range
            
    #Total journals
    @total_journals = @retro.journals.count
    @pie_data_journals = []
    @pie_labels_journals = []
    @max_journals = 0
    journals_group = @retro.journals.group_by{|journal| journal.user_id}
    journals_group.keys.sort.each do |user_id|
      @user_retro_hash.store user_id, new_user_retro.dup unless @user_retro_hash.has_key? user_id
      @user_retro_hash[user_id].store "journals", journals_group[user_id]
      @user_retro_hash[user_id].store "total_journals", journals_group[user_id].length
      @user_retro_hash[user_id].store "percentage_journals", (@user_retro_hash[user_id]["total_journals"].to_f / @total_journals * 100).round_to(1).to_i
      @max_journals = @user_retro_hash[user_id]["total_journals"] if @user_retro_hash[user_id]["total_journals"] > @max_journals
      @pie_data_journals << @user_retro_hash[user_id]["percentage_journals"]
      @pie_labels_journals << User.find(user_id).login + " #{@user_retro_hash[user_id]["percentage_journals"].to_s}%"
    end
    
    @max_range = @max_journals if @max_journals > @max_range
    
    
    #Total voting activity
    @total_votes = @retro.issue_votes.count
    @pie_data_votes = []
    @pie_labels_votes = []
    @max_votes = 0
    votes_group = @retro.issue_votes.group_by{|issue_vote| issue_vote.user_id}
    votes_group.keys.sort.each do |user_id|
      @user_retro_hash.store user_id, new_user_retro.dup unless @user_retro_hash.has_key? user_id
      @user_retro_hash[user_id].store "votes", votes_group[user_id]
      @user_retro_hash[user_id].store "total_votes", votes_group[user_id].length
      @user_retro_hash[user_id].store "percentage_votes", (@user_retro_hash[user_id]["total_votes"].to_f / @total_votes * 100).round_to(1).to_i
      @max_votes = @user_retro_hash[user_id]["total_votes"] if @user_retro_hash[user_id]["total_votes"] > @max_votes
      @pie_data_votes << @user_retro_hash[user_id]["percentage_votes"]
      @pie_labels_votes << User.find(user_id).login + " #{@user_retro_hash[user_id]["percentage_votes"].to_s}%"
    end
    
    @max_range = @max_votes if @max_votes > @max_range
    
    #Build Chart
    @point_totals = []
    @vote_totals = []
    @journal_totals = []
    @axis_labels = []
    x_axis = ''

    @user_retro_hash.keys.sort.each do |user_id|
      @point_totals << @user_retro_hash[user_id]["total_points"]
      @vote_totals << @user_retro_hash[user_id]["total_votes"]
      @journal_totals << @user_retro_hash[user_id]["total_journals"]
      x_axis = x_axis + User.find(user_id).login + '|'
    end
    @axis_labels << x_axis

    #Average time taken to complete a point?
        

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @retro }
    end
  end

  # GET /retros/new
  # GET /retros/new.xml
  def new
    @retro = Retro.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @retro }
    end
  end

  # GET /retros/1/edit
  def edit
    @retro = Retro.find(params[:id])
  end

  # POST /retros
  # POST /retros.xml
  def create
    @retro = Retro.new(params[:retro])

    respond_to do |format|
      if @retro.save
        flash[:notice] = 'Retro was successfully created.'
        format.html { redirect_to(@retro) }
        format.xml  { render :xml => @retro, :status => :created, :location => @retro }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @retro.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /retros/1
  # PUT /retros/1.xml
  def update
    @retro = Retro.find(params[:id])

    respond_to do |format|
      if @retro.update_attributes(params[:retro])
        flash[:notice] = 'Retro was successfully updated.'
        format.html { redirect_to(@retro) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @retro.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /retros/1
  # DELETE /retros/1.xml
  def destroy
    @retro = Retro.find(params[:id])
    @retro.destroy

    respond_to do |format|
      format.html { redirect_to(retros_url) }
      format.xml  { head :ok }
    end
  end
  
  def find_retro
    @retro = Retro.find(params[:id])
    @project = @retro.project
  end
  
  
  def find_project
      @project = Project.find(params[:project_id])
  end
end