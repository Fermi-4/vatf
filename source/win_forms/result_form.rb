require 'rubyclr'

#this module contains classes that are use to create forms using the .net library
module VatfWinForms

RubyClr::reference 'System.Windows.Forms'
RubyClr::reference 'System.Drawing'

include System::Windows::Forms
include System::Drawing  

# THis class is used to set results in subjective test cases
  class ResultForm 
    attr_reader :comment_text, :test_result
    
	#Constructor of the class. Takes form_title (string) the text that will be displayed as a title in the window
    def initialize(form_title = "Result Form")
      
      @test_result = 0 #Setting default result to 0 (retry)
	  
	  #Setting the Comment box of the form size, location, type, ...
      @comment_box = TextBox.new
      @comment_box.size = Size.new(285,50)
      @comment_box.location = Point.new(3,20)
      @comment_box.multiline = true
	  
	  #Setting the pass button parameter 
      @pass_button = Button.new
      @pass_button.text = "Pass"
      @pass_button.location = Point.new(10,90)
      @pass_button.click do 
        @comment_text = @comment_box.text
        @test_result = 1
        exit
      end
      
	  #Setting the fail button parameters
      @fail_button = Button.new
      @fail_button.text = "Fail"
      @fail_button.location = Point.new(105,90)
      @fail_button.click do 
        @comment_text = @comment_box.text
        @test_result = 2
        exit
      end 
      
	  #Setting the retry button parameters
      @retry_button = Button.new
      @retry_button.text = "Retry"
      @retry_button.location = Point.new(200,90)
      @retry_button.click do 
        @comment_text = ""
        @test_result = 0
        exit
      end 
      
	  #Adding a label for the comment box
      @comment_label = Label.new("Result comment")
      @comment_label.text = "Result comment"
      @comment_label.location = Point.new(3,3)
      @comment_label.auto_size = true
		
	  #Setting the Form parameters and adding the form control
      @res_form_height = 160
      @res_form = Form.new
      @res_form.text = form_title
      @res_form.size = Size.new(300,@res_form_height)
      @res_form.controls.add(@fail_button)
      @res_form.controls.add(@pass_button)
      @res_form.controls.add(@retry_button)
      @res_form.controls.add(@comment_label)
      @res_form.controls.add(@comment_box)
    end
	
	#Getter function of the text in the comment_box
	def comment_text
		if @comment_text.to_s.length > 0
			@comment_text
		else
			" "
		end
	end
    
	#Function to dsiplay the form
    def show_result_form
	  @res_form.size = Size.new(300,@res_form_height)
	  @res_form.show_dialog
	  rescue # This is a hack done because there is a problem between .net 2.0 Framework and rubyclr
    end
    
	#Function to dispose of the form
    def exit
      @res_form.close
    end
    
	#Function to add a link to the bottom of the form. Takes links_label (string) text to be displayed in the link; and a block of code ( {}, or do-end control block) that will be executed when the link is clicked.
    def add_link(links_label)
      form_link = Label.new
      form_link.text = links_label
      form_link.cursor = Cursors.Hand
      form_link.auto_size = true
      @res_form_height += 30
      form_link.location = Point.new(3,@res_form_height - 60)     
      form_link.click do |sender,args| 
        yield
        form_link.fore_color = Color.Red
        form_link.invalidate
      end
      @res_form.controls.add(form_link)
    end
  end
  
end

