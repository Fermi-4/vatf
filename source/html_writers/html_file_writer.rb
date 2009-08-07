require 'amrita/template'
require 'amrita/parts'
include Amrita
=begin
  WARNING!!!!!!!!!!!!! Before using this library you must install amrita in ruby.
=end
=begin
  This modules instatiates the basic elements for writing an ATF html page
=end
module Elements

=begin
    Class to created an html header in the file, sets the langauge to english, and the Page title to string given in session_title
=end
  class ATFHtmlHeader
    attr_reader :session_title
    def initialize(session_title)
      @session_title = session_title
    end
  end
 
=begin
  This class creates a cell in a row of a table in the page
=end 
  class DataCell
    public
      attr_reader :cell_data
    
    #Consructor of the class. Takes the cell's text, cell's format (a hash with html font attibutes i.e. {:color => "black} ), and cell's url as inputs (string).
      def initialize(cell_text, cell_format = nil, font_format = nil, cell_url = nil)
        @cell_format = cell_format
        @cell_text = SanitizedString[cell_text.to_s.gsub(/(\r|\n)+/,'<br />')]
        @font_format = font_format
        @cell_url = cell_url
      end
    
    #Attribute reader for the cell_data class attribute. Creates a <td></tr> entry in the file with format @cell_format
      def cell_data 
        if @cell_format
          e(:td,@cell_format){add_cell_url}
        else
          e(:td,{:bgcolor => "white"}){add_cell_url}
        end
      end
    
    private
    
    #Sets the font format for the text of the cell
      def add_font_format
        if @font_format
          e(:font, @font_format){@cell_text}
        else
          @cell_text
        end
      end
    
    #Sets hyperlink in the cell
      def add_cell_url
        if @cell_url
          c_url = '///' + @cell_url.gsub("\\","/")
          c_url = '///' + @cell_url if @cell_url.match(/^\w/) 
          e(:a, :href => c_url){add_font_format}
        else
          add_font_format
        end
      end   
  end

=begin
  This class creates a row inside a table.
=end
  class DataRows
    attr_reader :row_cells
    
    #Constructor of the class. Takes an array of cell data as parameter(an array or one or more DataCells i.e [["cell text",{cell format hash},{font format hash}, "cell url"],["cell text",{cell format hash},{font format hash}, "cell url"]]
    def initialize(row_data)
      @row_cells = Array.new
      row_data.each do |format|
	    if !format.kind_of?(Array)
		    format = [format]
		end
		@row_cells << DataCell.new(*format)
      end
    end
  end
  
=begin
  This class creates a table in the html page.
=end
  class DataTable
    attr_reader :table_data
    
    #Contructor of the class. Takes table_rows an array of rows (an array of one or more DataRows [DataRow,DataRow]) and table_format the table format (a hash with the format i.e. {:border => "1"}) as parameters
    def initialize(table_rows, table_format)
      @table_rows = table_rows
      @table_format = table_format
    end
    
    #Attribute reader for the table_data class attribute. Creates a <table></table> entry in the file with format @table_format, and adds the DataRow objects to the table
    def table_data
      rows_array = Array.new
      @table_rows.each{|val| rows_array << DataRows.new(val)}
      e(:table, @table_format){rows_array}
    end
  end
  
=begin
  This class adds a Header to the html page
=end
  class PageTitle
    attr_reader :page_title
    
    #Constructor of the class. Adds a <hx></hx> entry in the page, where x represents the header type (a number greater than 0). Takes page_title the header text (string), type the header type (a number greater than 0), and format the font format (a hash containing the format i.e. {:color => "black"}) as parameters.
    def initialize(page_title, type, format)
      @page_title = e(("h"+type).to_sym, format){page_title}
    end
    
  end

=begin
  This class adds a paragraph <p></p> entry in the page.
=end  
  class PageText
    attr_reader :page_text
    
    #Constructor of the class. Takes page_text the paragraph's text (string), font_format the font format (a hash containing the format i.e. {:color => "black"}), line_format the paragraph's format (a hash containing the format i.e. {:align => "left"}), and link a url (string) as parameters.
    def initialize(page_text, font_format = nil, line_format = nil, link = nil)
      @p_text = SanitizedString[page_text.to_s.gsub(/(\r|\n)+/,'<br />')]
      @font_format = font_format
      @line_format = line_format
      @link = link
    end
    
    #Attribute reader. Creates the <p></p> entry in the page
    def page_text
      if @line_format
        e(:p, @line_format){add_url}
      else
        e(:p){add_url}
      end
    end
    
    private
    #Adds the font formatting entry to the paragraph
    def add_font_format
      if @font_format
        e(:font,@font_format){@p_text}
      else
        @p_text
      end
    end
    
    #Adds a link in the paragraph to the url specified by @link
    def add_url
      if @link
        l_url = '///' + @link.gsub("\\","/")
        l_url = '///' + @link if @link.match(/^\w/)
        e(:a, :href => l_url){add_font_format}
      else
        add_font_format
      end
    end
  end
  
end

module HTMLWriters
#includes the precious module to this library
include Elements

=begin
    HTML parts class library complements the previous module. This is required so that the amrita library can map the classes in the Elements
    module to the html syntax.
=end  
  class ATFHtmlParts
    attr_reader :parts_template
    #html Parts template used to map the classes from the Elements module to html syntax
    @@parts_template = TemplateText.new <<END
      <span class=PageTitle>
        <span id=page_title></span>    
      </span>
      
    <span class=PageText>
        <span id=page_text></span>  
    </span>
    
    <span class=ATFHtmlHeader>
      <head>
        <meta http-equiv="Content-Language" content="en-us">
        <meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
        <title id="session_title"></title>
      </head>
    </span>
    
    <span class=DataCell>
      <span id=cell_data></span>
    </span>
    
    <span class=DataRows>
      <tr align=center >      
        <span id=row_cells></span>
      </tr>
    </span>
    
    <span class=DataTable>
      <span id=table_data>
      </span>
    </span>
    
END

    #Constructos of the class. This is where the classes in the Elements module are mapped to html syntax.
    def initialize
      @@parts_template.install_parts_to(Elements)
    end 
  end

=begin
    This is the ATF html base class. All html writer's in the ATF should be based on this class.
=end
  class ATFHtmlFile

   private
   
      #This function adds a tag to the template where an html element should be. Takes element_name the name of the element as paramter.
      #Returns a symbol that points to the tag created for that element.  
      def add_to_template(element_name)
        symbol_text = element_name+rand(Time.now.to_i).to_s
        @template_string = @template_string.gsub("</body>","\t<span id="+symbol_text+"></span>\n\t</body>")
        symbol_text.to_sym
      end
      
    public 
      
      #Constructor of the class. Takes file_path the html file path, and window_header the html window header as parameters.
      def initialize(file_path, window_header)
        @file_path = file_path
        ATFHtmlParts.new()
        @data = Hash.new
        @data_tables = Hash.new
        @data[:file_header] = ATFHtmlHeader.new(window_header)
        @template_string = <<END_OF_TEMPLATE
        <html>
          <span id=file_header></span>
          <body>
          </body>
        </html>
END_OF_TEMPLATE
      end
      
      #Function to build the html file. This function creates the html file, when this functions is called all
      #the classes are replaced by their html counterpart and written to the file.
      def write_file
        html_file_writer = File.new(@file_path,"w")
        @html_file_template = TemplateText.new(@template_string)
        @html_file_template.prettyprint = true
        @data_tables.each{|key,val| @data[key]= DataTable.new(val["rows"],val["format"])}
        @html_file_template.expand(html_file_writer,@data)
        html_file_writer.close
      end
      
      #This function adds a text paragraph to the html file. Takes line_text the paragraph's text (string), font_format the font format (a hash containing the format i.e. {:color => "black"}), line_format the paragraph's format (a hash containing the format i.e. {:align => "left"}), and link a url (string) as parameters.
      def add_paragraph(line_text, font_format = nil, line_format= nil, link = nil)
        line_symbol = add_to_template("line")
        @data[line_symbol] = [PageText.new(line_text, font_format, line_format, link)]
        line_symbol
      end
      
      #This function add a table to the html file. Takes table_rows the table's rows (an array of rows i.e. [row1,row1], where each "row"  has is a  [["cell text",{cell format hash},{font format hash}, "cell url"],.....["cell text",{cell format hash},{font format hash}, "cell url"]] structure, from these values only the cell_text is a required ), and table_format the table's format (a hash containing the format i.e. {:border => "1", :width => "100%"}) as parameters.
      #Returns the table's symbol
      def add_table(table_rows, table_format = {:border => "1", :width => "100%"})
        table_sym = add_to_template("table")
        @data_tables[table_sym] = {"rows" => [table_rows],"format" => table_format}
        table_sym
      end
      
      #This function adds one row to the table specified by table symbol. Takes table_symbol the table's symbol, and row_data the row ( an array with the following structure [["cell text",{cell format hash},{font format hash}, "cell url"],.....["cell text",{cell format hash},{font format hash}, "cell url"]] structure, from these values only the cell_text is a required) to be added as parameter.
      def add_row_to_table(table_symbol, row_data)
        @data_tables[table_symbol]["rows"] << row_data
      end
      
      #This function adds one or more rows to a table referenced by table_symbol. Takes table_symbol the table's synbol as parameter, and rows the rows (an array of rows i.e. [row1,row1], where each "row"  has is a  [["cell text",{cell format hash},{font format hash}, "cell url"],.....["cell text",{cell format hash},{font format hash}, "cell url"]] structure, from these values only the cell_text is a required)to be added 
      def add_rows_to_table(table_symbol, rows)
        rows.each{|row| add_row_to_table(table_symbol, row)}
      end
      
      #This function adds a Title to the page. Takes title the title to be added (string), the title_type title type ( a number greater than 0), and format the font format (a hash containing the format i.e. {:color => "black"}) as parameters.
      def add_text_title(title, title_type = 1, format = {:align => "center"})
        title_symbol = add_to_template("title")
        @data[title_symbol] = [PageTitle.new(title, title_type.to_s, format)]
      end

  end

end
