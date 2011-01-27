
class Omnifind
  
  attr_accessor :total_results, :estimated_results, :start_index, :items_per_page, :first_query, :next_query, :last_query, :previous_query, :entries
  
  def initialize(query, index, opts = {})
    
    request_url = "http://search.asee.org/api/search?index=#{index}&query=#{query}&queryTimeout=3000"
    
    if opts[:fields].present?
      fields = Array(opts[:fields]).join("|")
      request_url += "&fields=#{CGI.escape(fields)}"
    end
    
    doc = Nokogiri::XML(open(request_url))
    
    # TODO:  Make this integers or nil?
    @total_results = doc.xpath("//opensearch:totalResults").text
    @estimated_results = doc.xpath("//omnifind:estimatedResults").text
    @start_index = doc.xpath("//opensearch:startIndex").text
    @items_per_page = doc.xpath("//opensearch:itemsPerPage").text
    
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
    end

  
  end
  
end

# s = Omnisearch.new('test', 'jee.org', :fields => "author")