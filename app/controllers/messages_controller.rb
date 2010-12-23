class MessagesController < ApplicationController
  before_filter :set_scoping
  
  def set_scoping
    if params[:host_id]
      @scope = Message.where(:host => Base64.decode64(params[:host_id]))
    else
      @scope = Message
    end
  end
  
  def index
    @has_sidebar = true
    @load_flot = true

    if params[:filters].blank?
      @messages = @scope.all_with_blacklist params[:page]
    else
      @messages = @scope.all_by_quickfilter params[:filters], params[:page]
    end
    @total_count =  Message.count_since(0)
    @total_blacklisted_terms = BlacklistedTerm.count

    @favorites = FavoritedStream.all_of_user(current_user.id)
  end

  def show
    @message = Message.find params[:id]
  end

  def showrange
    @has_sidebar = true
    @load_flot = true
    
    begin
      @from = Time.at(params[:from].to_i)
      @to = Time.at(params[:to].to_i)
    rescue
      flash[:error] = "Missing or invalid range parameters."
    end

    @messages = Message.all_in_range(params[:page], @from.to_i, @to.to_i)
    @total_count = Message.count_all_in_range(@from.to_i, @to.to_i)
  end

  def getcompletemessage
    message = Message.find params[:id]
    render :text => CGI.escapeHTML(message.message)
  end
  
  def deletebystream
    begin
      conditions = Message.all_of_stream(params[:id].to_i, 0).criteria.sources
      throw "Missing conditions" if conditions.blank?

      Message.set(conditions, :deleted => true )

      flash[:notice] = "Messages have been deleted."
    rescue => e
      flash[:error] = "Could not delete messages."
    end
    
    redirect_to :controller => "streams", :action => "show", :id => params[:id]
  end

  def deletebyquickfilter
    begin
      filters = JSON.parse(params[:filters])

      filters_with_symbols = Hash.new
      filters_with_symbols[:message] = filters["message"]
      filters_with_symbols[:facility] = filters["facility"]
      filters_with_symbols[:severity] = filters["severity"]
      filters_with_symbols[:host] = filters["host"]

      conditions = Message.all_by_quickfilter(filters_with_symbols, 0, 0).criteria.sources
      throw "Missing conditions" if conditions.blank?

      Message.set(conditions, :deleted => true )

      flash[:notice] = "Messages have been deleted."
    rescue
      flash[:error] = "Could not delete messages."
    end

    redirect_to :action => 'index'
  end

  def deletebystream
    begin
      conditions = Message.by_stream(params[:id].to_i).criteria.to_hash
      throw "Missing conditions" if conditions.blank?

      Message.set(conditions, :deleted => true)

      flash[:notice] = "Messages have been deleted."
    rescue
      flash[:error] = "Could not delete messages."
    end
    
    redirect_to :controller => "streams", :action => "settings", :id => params[:id]
  end

  def getsimilarmessages
    # Get the message we want to compare.
    message = Message.find params[:id]
    message_id = message.id
    message = message.message

    ## Prepare comparison
    # Cut until first ':' if there is one and it is in the first half of the message (this is usually the hostname)
    if message.include?(':') and message.index(':') <= message.length/2
      message = message[message.index(':')+1..message.length].strip
    end

    # Get first 30% chars of message. This is what we will do a REGEX search over all messages.
    get_chars = ((message.length.to_f)/100*30).to_i
    message = message[0..get_chars]

    ## Get the messages
    # Blacklist
    conditions = Message.by_blacklisted_terms(Blacklist.all_terms)

    # Add our search condition.
    conditions = conditions.where(:message.in => [/#{Regexp.escape(message)}/])

    # Don't search for the message we used to compare.
    conditions = conditions.where(:id.nin => [message_id])

    # Get the messages.
    @messages = conditions.limit(50).order("$natural DESC")

    if @messages.blank?
      render :text => "No similar messages found"
      return
    end

    @inline_version = true
    render :partial => "table"
  end
end
