
require 'wx'

#Class used to create a Result Frame, do not call directly
class ResultFrame < Wx::Frame
  
  include Wx
  
  attr_reader :result
  
  def initialize(title)
    @result = ''
    super(nil, -1, title)
    @res_panel = Panel.new(self)
    @c_label = StaticText.new(@res_panel, -1, 'Comment', 
                DEFAULT_POSITION, DEFAULT_SIZE, ALIGN_LEFT)
    @c_textbox = TextCtrl.new(@res_panel, nil, :style=>Wx::TE_MULTILINE)
    @button_panel = Panel.new(@res_panel)
    @action_button_panel = Panel.new(@res_panel)
    @p_button = Button.new(@button_panel, -1, 'Pass')
    evt_button(@p_button.get_id()) { |event| pass_button_click()}
    @f_button = Button.new(@button_panel, -1, 'Fail')
    evt_button(@f_button.get_id()) { |event| fail_button_click()}
    @r_button = Button.new(@button_panel, -1, 'Retry') 
    evt_button(@r_button.get_id()) { |event| retry_button_click()}
    @res_panel_sizer = BoxSizer.new(VERTICAL)
    @b_panel_sizer = BoxSizer.new(HORIZONTAL)
    @a_chan_sizer = BoxSizer.new(VERTICAL)
    @res_panel.set_sizer(@res_panel_sizer)
    @button_panel.set_sizer(@b_panel_sizer)
    @action_button_panel.set_sizer(@a_chan_sizer)
    @res_panel_sizer.add(@c_label, 0, GROW|ALL, 2)
    @res_panel_sizer.add(@c_textbox, 2, GROW|ALL, 2)
    @res_panel_sizer.add(@button_panel, 0, GROW|ALL, 2)
    @res_panel_sizer.add(@action_button_panel, 0, GROW|ALL, 2)
    @b_panel_sizer.add(@p_button, 1, GROW|ALL, 2)
    @b_panel_sizer.add(@f_button, 1, GROW|ALL, 2)
    @b_panel_sizer.add(@r_button, 1, GROW|ALL, 2)
  end
  
  #Function to add one or more buttons at the same level in the form, takes
  #  *button_info, one or more hashes with the following entries:
  #                { 'name' => <string to be displayed on the button>,
  #                  'action' => <pointer of function to run on button click>,
  #                  'action_params' => <array of parameters to pass to the
  #                                      function pointed by action>}
  def add_buttons(*buttons_info)
    b_panel = Panel.new(@action_button_panel)
    b_panel_sizer = BoxSizer.new(HORIZONTAL)
    b_panel.set_sizer(b_panel_sizer)
    buttons_info.each do |current_button|
      button = Button.new(b_panel, -1, current_button['name'])
      evt_button(button.get_id()) do |event| 
        if current_button['action_params']
          send(current_button['action'], current_button['action_params'])
        else
          send(current_button['action'])
        end
      end
      b_panel_sizer.add(button, 1, GROW|ALL, 2)
    end
    @a_chan_sizer.add(b_panel, 0, GROW|ALL, 2)
  end
  
  #Function to handle pass button click events
  def pass_button_click()
    @result=[FrameworkConstants::Result[:pass], @c_textbox.get_value]
    self.close()
  end
  
  #Function to handle fail button click events
  def fail_button_click()
    @result=[FrameworkConstants::Result[:fail], @c_textbox.get_value]
    self.close()
  end
  
  #Function to handle retry button click events
  def retry_button_click()
    @result=[FrameworkConstants::Result[:nry], @c_textbox.get_value]
    self.close()
  end
end

#App class that will be forked do not call directly
class ResultApp < Wx::App
  
  def initialize(title="Test Result")
    @title=title
    super()
  end
  
  def on_init()
    @frame = ResultFrame.new(@title)
    @action_buttons.each{ |buttons| @frame.add_buttons(*buttons) } if @action_buttons
    @frame.show
  end
   
  #Function to add one or more buttons at the same level in the form, takes
  #  *button_info, one or more hashes with the following entries:
  #                { 'name' => <string to be displayed on the button>,
  #                  'action' => <pointer of function to run on button click>,
  #                  'action_params' => <array of parameters to pass to the
  #                                      function pointed by action>}
  def add_buttons(*buttons_info)
    @action_buttons = [] if !@action_buttons
    @action_buttons << buttons_info
  end
  
  #Funtion to obtain the results of the click.
  #Returns an arrays [FrameworkConstants::Result[], <string typed in the comment textbox>]
  def get_result()
    @frame.result
  end
   
  def on_exit
    super()
  end
end

#Class to create a result window and display this is the class that should be called
#to create a result window in the script
#Example usage
#  res_win = ResultWindow.new(title) create the window
#  #Add additional buttons in two rows
#  res_win.add_buttons({'name' => 'test', 'action' => :puts, 'action_params' => 'AAAAAAAAAAA'})
#  res_win.add_buttons({'name' => 'test2', 'action' => :puts, 'action_params' => 'BBBBBBBBBB'}, 
#                      {'name' => 'test2', 'action' => :puts, 'action_params' => 'CCCCCCCCCC'}) 
#  #show window
#  res_win.show()
#  #get the results from the window
#  puts "This is result" + res_win.get_result().to_s
class ResultWindow
  def initialize(title)
    @title = title
    @b_arr = []
  end
  
  def add_buttons(*buttons_info)
    @b_arr << buttons_info
  end
  
  def show()
    read, write = IO.pipe()
    w_pid = Process.fork() do
      read.close
      app = ResultApp.new(@title)
      @b_arr.each{ |c_buttons| app.add_buttons(*c_buttons) }
      app.main_loop
      Marshal.dump(app.get_result(),write)
    end
    write.close
    result = read.read
    Process.wait(w_pid)
    @result = Marshal.load(result)
  end
  
  def get_result()
    @result
  end
end

