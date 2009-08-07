require 'rubyclr'
require File.dirname(__FILE__)+'/result_form'
#this module contains classes that are use to create forms using the .net library
module VatfWinForms 

# THis class is used to set results in subjective test cases
  class ScrollableResultForm <  ResultForm
    
  #Constructor of the class. Takes form_title (string) the text that will be displayed as a title in the window
    def initialize(form_title = "Result Form")
      super(form_title)
          
    #Adding Panel that will contain all the links
      @link_panel_height = 20
      @link_panel = Panel.new
      @link_panel.border_style = BorderStyle.new(2)
      @link_panel.location = Point.new(3,130)
      @link_panel.bring_to_front
      @link_panel.auto_scroll = true
 
      @res_form.controls.add(@link_panel)
      
      @res_form.resize do
        @link_panel.size = Size.new(@res_form.size.width - 15, @res_form.size.height - 175)
        @comment_box.size = Size.new(@res_form.size.width - 15, @comment_box.size.height)
        @pass_button.size = Size.new((@res_form.size.width/3 - 20).floor, @pass_button.size.height)
        @fail_button.size = Size.new((@res_form.size.width/3 - 20).floor, @fail_button.size.height)
        @fail_button.location = Point.new(@pass_button.location.x + @pass_button.size.width + 15, @fail_button.location.y)
        @retry_button.size = Size.new((@res_form.size.width/3 - 20).floor, @retry_button.size.height)
        @retry_button.location = Point.new(@fail_button.location.x + @fail_button.size.width + 15, @retry_button.location.y)
      end
    end
  
  #Function to dsiplay the form
    def show_result_form
      @res_form.size = Size.new(300,[@res_form_height,300].min)
      @res_form.show_dialog
      rescue # This is a hack done because there is a problem between .net 2.0 Framework and rubyclr
    end
    
  #Function to add a link to the bottom of the form. Takes links_label (string) text to be displayed in the link; and a block of code ( {}, or do-end control block) that will be executed when the link is clicked.
    def add_link(links_label)
      panel_link = Label.new
      panel_link.text = links_label
      panel_link.cursor = Cursors.Hand
      panel_link.auto_size = true
      @res_form_height += 30
      @link_panel_height += 30
      panel_link.location = Point.new(3,@link_panel_height - 30)     
      panel_link.click do |sender,args| 
        yield
        panel_link.fore_color = Color.Red
        @link_panel.refresh
      end
      @link_panel.controls.add(panel_link)
    end
  end
  
end

