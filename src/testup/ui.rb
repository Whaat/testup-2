#-------------------------------------------------------------------------------
#
# Copyright 2013-2014 Trimble Navigation Ltd.
# License: The MIT License (MIT)
#
#-------------------------------------------------------------------------------


module TestUp

  def self.init_ui
    return if file_loaded?(__FILE__)

    # Commands
    cmd = UI::Command.new('Open TestUp') {
      self.toggle_testup
    }
    cmd.tooltip = 'Open TestUp'
    cmd.status_bar_text = 'Open TestUp for running tests.'
    cmd.small_icon = File.join(PATH_IMAGES, 'testup-16.png')
    cmd.large_icon = File.join(PATH_IMAGES, 'testup-24.png')
    cmd.set_validation_proc {
      MF_CHECKED if self.window && self.window.visible?
    } if defined?(Sketchup)
    cmd_toggle_testup = cmd

    cmd = UI::Command.new('Run tests in Ruby Console') {
      self.toggle_run_in_gui
    }
    cmd.tooltip = 'Run in Console'
    cmd.status_bar_text = 'Enable to output test results in the Ruby Console.'
    cmd.small_icon = File.join(PATH_IMAGES, 'console.png')
    cmd.large_icon = File.join(PATH_IMAGES, 'console.png')
    cmd.set_validation_proc {
      MF_CHECKED if !self.settings[:run_in_gui]
    } if defined?(Sketchup)
    cmd_toggle_run_tests_in_console = cmd

    cmd = UI::Command.new('Verbose Console Tests') {
      self.toggle_verbose_console_tests
    }
    cmd.tooltip = 'Verbose Console Tests'
    cmd.status_bar_text = 'Enable verbose test results in the Ruby Console.'
    cmd.small_icon = File.join(PATH_IMAGES, 'verbose.png')
    cmd.large_icon = File.join(PATH_IMAGES, 'verbose.png')
    cmd.set_validation_proc {
      flags = 0
      flags |= MF_GRAYED if self.settings[:run_in_gui]
      flags |= MF_CHECKED if self.settings[:verbose_console_tests]
      flags
    } if defined?(Sketchup)
    cmd_toggle_verbose_console_tests = cmd

    cmd = UI::Command.new('Reload TestUp') {
      TESTUP_CONSOLE.clear
      window_visible = @window && @window.visible?
      @window.close if window_visible
      @window = TestUpWindow.new
      @window.show if window_visible
      puts "Reloaded #{self.reload} files!"
    }
    cmd.tooltip = 'Reload TestUp'
    cmd.small_icon = File.join(PATH_IMAGES, 'arrow_refresh.png')
    cmd.large_icon = File.join(PATH_IMAGES, 'arrow_refresh.png')
    cmd_reload_testup = cmd

    cmd = UI::Command.new('Minitest Help') {
      self.display_minitest_help
    }
    cmd.tooltip = 'Minitest Help'
    cmd.small_icon = File.join(PATH_IMAGES, 'help.png')
    cmd.large_icon = File.join(PATH_IMAGES, 'help.png')
    cmd_display_minitest_help = cmd

    cmd = UI::Command.new('Run Tests') {
      self.run_tests_gui
    }
    cmd.tooltip = 'Discover and run all tests.'
    cmd.status_bar_text = 'Discover and run all tests.'
    cmd_run_tests = cmd

    cmd.tooltip = 'Run Layout Tests'
    cmd.small_icon = File.join(PATH_IMAGES, 'layout-16.png')
    cmd.large_icon = File.join(PATH_IMAGES, 'layout-24.png')
    cmd_run_layout_tests = cmd

    cmd = UI::Command.new('Run Tests') {
      self.run_tests_gui
    }
    cmd.tooltip = 'Discover and run all tests.'
    cmd.status_bar_text = 'Discover and run all tests.'
    cmd_run_tests = cmd

    # Menus
    if defined?(Sketchup)
      menu = UI.menu('Plugins').add_submenu(PLUGIN_NAME)
      menu.add_item(cmd_toggle_testup)
      if TestUp::DEBUG
        menu.add_separator
        menu.add_item(cmd_toggle_run_tests_in_console)
        menu.add_item(cmd_toggle_verbose_console_tests)
        menu.add_item(cmd_display_minitest_help)
        menu.add_separator
        menu.add_item(cmd_run_tests)
        menu.add_separator
        menu.add_item(cmd_reload_testup)
      end
    end

    # Toolbar
    if defined?(Sketchup)
      toolbar = UI::Toolbar.new(PLUGIN_NAME)
      toolbar.add_item(cmd_toggle_testup)
      if TestUp::DEBUG
        toolbar.add_separator
        toolbar.add_item(cmd_toggle_run_tests_in_console)
        toolbar.add_item(cmd_toggle_verbose_console_tests)
        toolbar.add_item(cmd_display_minitest_help)
        toolbar.add_separator
        toolbar.add_item(cmd_reload_testup)
      end
      toolbar.restore
    end

    # Ensure this method is run only once.
    file_loaded(__FILE__)
  end


  module SystemUI

    def self.select_directory(options)
      if defined?(UI) && UI.respond_to?(:select_directory)
        result = UI.select_directory(options)
        if options && options[:select_multiple]
          result.map! { |path| File.expand_path(path) }
        else
          result = File.expand_path(result)
        end
        result
      else
        self.select_directory_fallback(options)
      end
    end

    BIF_RETURNONLYFSDIRS = 0x00000001
    BIF_EDITBOX = 0x00000010
    BIF_NEWDIALOGSTYLE = 0x00000040
    BIF_UAHINT = 0x00000100

    def self.select_directory_fallback(options)
      unless RUBY_PLATFORM =~ /mswin|mingw/
        warn "select_directory_fallback not implemented for this platform"
        return nil
      end

      require 'win32ole'
      default_path = File.join(ENV['HOME'], 'Desktop').gsub('/', '\\')

      message = ""
      select_multiple = false
      if options
        message = options[:message] || message
        select_multiple = options[:select_multiple] || select_multiple
      end

      objShell = WIN32OLE.new('Shell.Application')
      parent_window = TestUp::Win32Helper.get_main_window_handle
      dialog_options = BIF_RETURNONLYFSDIRS | BIF_NEWDIALOGSTYLE | BIF_EDITBOX

      # http://msdn.microsoft.com/en-us/library/windows/desktop/bb774065(v=vs.85).aspx
      objFolder = objShell.BrowseForFolder(parent_window, message, dialog_options)

      return nil if objFolder.nil?
      path = objFolder.Self.Path
      unless File.exist?(path)
        UI.messagebox("Unable to handle '#{path}'.")
        return nil
      end
      directory = File.expand_path(path)

      if select_multiple
        [directory]
      else
        directory
      end
    end

  end # module SystemUI

end # module
