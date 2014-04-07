require 'spec_helper'

describe Githug::Profile do

  describe ".load" do
    it "loads the profile" do
      settings = {:folder => nil, :level => 1, :current_attempts => 0, :current_hint_index => 0, :current_levels => [], :completed_levels => []}
      File.should_receive(:exists?).with(Githug::Profile::PROFILE_FILE).and_return(true)
      File.should_receive(:open).with(Githug::Profile::PROFILE_FILE).and_return("settings")
      YAML.should_receive(:load).with("settings").and_return(settings)
      Githug::Profile.should_receive(:new).with(settings)
      Githug::Profile.load
    end

    it "loads the defaults if the file does not exist" do
      defaults = {:folder => nil, :level => nil, :current_attempts => 0, :current_hint_index => 0, :current_levels => [], :completed_levels => []}
      File.should_receive(:exists?).with(Githug::Profile::PROFILE_FILE).and_return(false)
      Githug::Profile.should_receive(:new).with(defaults)
      Githug::Profile.load
    end
  end

  it "allows method acces to getters and setters" do
    profile = Githug::Profile.load
    profile.level.should eql(nil)
    profile.level = 1
    profile.level.should eql(1)
  end

  describe ".save" do

    it "saves the file" do
      profile = Githug::Profile.load
      File.should_receive(:open).with(Githug::Profile::PROFILE_FILE, "w")
      profile.save
    end

  end

  describe "level methods" do

    let(:profile) { Githug::Profile.load }

    before(:each) do
      profile.stub(:save)
      @levels = Githug::Level::LEVELS
      Githug::Level::LEVELS = ["init", "add", "rm", "rm_cached", "diff"]
      profile.level = "init"
    end

    after(:each) do
      Githug::Level::LEVELS = @levels
    end

    describe "#level_bump" do

      it "bumps the level" do
        profile.should_receive(:set_level).with("add")
        profile.level_bump
      end

      it "resets the current_attempts" do
        profile.current_attempts = 1
        profile.level_bump
        profile.current_attempts.should eql(0)
      end

      it "sets the level to the first incomplete level" do
        profile.level = "rm_cached"
        profile.completed_levels = ["init", "add"]
        profile.level_bump
        profile.level.should eql("rm")
      end
    end

    describe "#set_level" do

      it "sets the level" do
        profile.should_receive(:save)
        profile.should_receive(:reset!)
        profile.set_level("rm")
        profile.settings[:level].should eql("rm")
      end

    end

    describe "#folder=" do

      context("when folder is not 'default'") do
        it "sets the folder and sets the current level to the first one in the config file" do
          config_file = double("config_file")
          config_file.should_receive(:readlines).and_return(%W(level1\n level2\n level3\n))
          File.should_receive(:new).with("/path/to/level_folder/config").and_return(config_file)
          profile.should_receive(:set_level).with(nil)
          profile.folder = "/path/to/level_folder"
          profile.settings[:folder].should eql("/path/to/level_folder")
          profile.settings[:current_levels].should eql(%W(level1 level2 level3))
          profile.settings[:completed_levels] = []
        end
      end

      context("when folder is not 'default'") do
        it "sets the folder to nil and the current level to 'LEVELS[0]'" do
          profile.should_receive(:set_level).with(Githug::Level::LEVELS[0])
          profile.folder = "default"
          profile.settings[:folder].should eql(nil)
          profile.settings[:current_levels].should eql(Githug::Level::LEVELS)
          profile.settings[:completed_levels] = []
        end
      end

    end

  end


end
