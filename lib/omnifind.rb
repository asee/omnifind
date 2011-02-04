
class Omnifind
  
  attr_accessor :total_results, :estimated_results, :start_index, :items_per_page, :first_query, :next_query, :last_query, :previous_query, :entries, :error, :request_url
  
  def initialize(opts = {})
    @entries = []
    
    validate_init_options(opts)

    # Default some options
    @items_per_page = (opts[:items_per_page].to_i > 0) ? opts[:items_per_page].to_i : 10
    
    @request_url = ''
    @request_url << (opts.delete(:protocol) || 'http')
    @request_url << '://' unless @request_url.match("://")
    @request_url << opts[:host]
    @request_url.chop! if @request_url.last == '/'
    
    # A little backwards in order, but save the host in case we need to build a link to it later
    @request_host = @request_url.dup
    
    
    @request_url << "/api/search?index=#{CGI.escape(opts[:index])}&query=#{CGI.escape(opts[:query])}&queryTimeout=3000&results=#{opts[:items_per_page]}"
    
    if opts[:fields].present?
      fields = Array(opts[:fields]).join("|")
      @request_url << "&fields=#{CGI.escape(fields)}"
    end
    
    if opts[:page].present? && opts[:page].to_i > 0
      offset = (opts[:page].to_i - 1) * opts[:items_per_page]
      @request_url << "&start=#{offset}" if offset >= opts[:items_per_page]
    end
    
    begin
      doc = Nokogiri::XML(open(@request_url))
    
      # TODO:  Make this integers or nil?
      @total_results = doc.xpath("//opensearch:totalResults").text.to_i
      @estimated_results = doc.xpath("//omnifind:estimatedResults").text.to_i
      @start_index = doc.xpath("//opensearch:startIndex").text.to_i
      # This will get set to either the requested items per page, or the number of items in the page, whichever is less.
      # Having it as the lesser amount will throw off will paginate calculations, so don't read it in.
      # @items_per_page = doc.xpath("//opensearch:itemsPerPage").text.to_i
    
      @first_query = doc.css("link[rel='first']").first.try(:attributes).try(:[], "href").try(:text)
      @next_query = doc.css("link[rel='next']").first.try(:attributes).try(:[], "href").try(:text)
      @last_query = doc.css("link[rel='last']").first.try(:attributes).try(:[], "href").try(:text)
      @previous_query = doc.css("link[rel='previous']").first.try(:attributes).try(:[], "href").try(:text)
    
      @entries = (doc / "entry").collect do |entry|
        entry_attrs = { 
          :title => CGI.unescapeHTML(entry.css("title").first.try(:text)), 
          :relevance => entry.xpath("relevance:score").text,
          :url => entry.css("id").first.try(:text),
          :summary => CGI.unescapeHTML(entry.css("summary").first.try(:text)),
          :fields => HashWithIndifferentAccess[
              *entry.xpath("omnifind:field").collect{ |x| 
                x.attributes.nil? ? nil : [x.attributes["name"].try(:text), x.text.try(:strip)] }.compact.flatten
            ]
        }
        
        alternate_url = entry.css("link[rel='alternate']").first.try(:attributes).try(:[], "href").try(:text)
        if alternate_url.present?
          entry_attrs[:alternate_url] = @request_host + alternate_url.gsub("api/search/fetch?", "search/click?")
        end
        
        entry_attrs
      end
    rescue Exception => e
      @error = e
    end
  end
  
  def next_start_index
    start_index + items_per_page - 1
  end
  
  def previous_start_index
    prev = start_index - items_per_page
    prev < 0 ? nil : prev
  end
  
  def first_start_index
    0
  end
  
  def last_start_index
    (total_results / items_per_page) * items_per_page
  end
  
  
  def validate_init_options(opts)
    if opts[:path].blank? && (opts[:index].blank? || opts[:query].blank?)
      raise ArgumentError.new("Expected options to include either index and query, or a full path") 
    elsif opts[:host].blank?
      raise ArgumentError.new("Options must include a host")
    end
  end
  
  def total_pages
     total_results / items_per_page
  end
  
  def paginate
    page_num = begin
      if items_per_page == 0
        1
      else
        (start_index / items_per_page) + 1
      end
    end
    WillPaginate::Collection.create(
        page_num,
        (items_per_page == 0 ? 10 : items_per_page),
        total_results
    ) { |pager|
      pager.replace entries
    }    
  end
  
  
  
  
end

# s = Omnisearch.new('test', 'jee.org', :fields => "author")