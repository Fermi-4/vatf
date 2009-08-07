####################### Readme file for the db_handler.rb ####################

Steps required for the db_handler.rb to work:
 
-Install gem activerecord (if not installed). To do so, open command prompt and run: "gem install activerecord -p http://wwwgate.ti.com:80"; if you get an exception in config_file.rb then Copy config_file.rb from ../ruby_extensions/ to .\ruby\lib\ruby\site_ruby\1.8\rubygems and run the command again. 

-Copy active_record.rb from ../ruby_extensions/ to .\ruby\lib\ruby\gems\1.8\gems\activerecord-1.15.3\lib

-Copy msaccess_adapter.rb from ../ruby_extensions/ to .\ruby\lib\ruby\gems\1.8\gems\activerecord-1.15.3\lib\active_record\connection_adapters

-From the command prompt change directory to .\ruby\lib\ruby\gems\1.8\gems\activerecord-1.15.3

-From this directory run: "ruby install.rb"

After these steps, db_handler.rb is ready for use
