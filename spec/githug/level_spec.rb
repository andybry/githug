require 'spec_helper'
require 'grit'
require 'fileutils'

describe Githug::Level do

  let(:subject) { Githug::Level.load_from_file(File.expand_path("spec/support/files/test_level.rb")) }
  let(:repo) { mock(:reset) }

  before(:each) do
    Githug::Repository.stub(:new).and_return(repo)
    Githug::UI.stub(:puts)
    Githug::UI.stub(:print)
  end

  it "should mixin UI" do
    Githug::Level.ancestors.should include(Githug::UI)
  end

  describe ".load" do

    context("when the profile has a folder option") do
      it "loads the level from the folder" do
        profile = double("profile")
        profile.should_receive(:folder).and_return("/path/to/level_folder")
        Githug::Profile.should_receive(:load).and_return(profile)
        Githug::Level.should_receive(:setup).with("/path/to/level_folder/init.rb")
        Githug::Level.load("init")
      end
    end

    context("when the profile has no folder option") do
      it "loads the level from the levels folder of the gem" do
        profile = double("profile")
        profile.should_receive(:folder).and_return(nil)
        Githug::Profile.should_receive(:load).and_return(profile)
        File.stub(:dirname).and_return("")
        Githug::Level.should_receive(:setup).with("/../../levels/init.rb")
        Githug::Level.load("init")
      end
    end


    it "returns false if the level does not exist" do
      File.stub(:exists?).and_return(false)
      Githug::Level.load(1).should eql(false)
    end

  end

  describe ".list" do
    it "lists the levels without nil" do
      Githug::Level.list.should eql(Githug::Level::LEVELS - [nil])
    end
  end

  describe ".levels" do
    let(:profile) { double("profile") }
    context("when there is a folder option in the profile") do
      it "retrieves the list of levels from the config file in that folder" do
        profile = double("profile")
        profile.should_receive(:folder).and_return("/path/to/level_folder")
        Githug::Profile.should_receive(:load).and_return(profile)
        config_file = double("config_file")
        config_file.should_receive(:readlines).and_return(%W(level1\n level2\n level3\n))
        File.should_receive(:new).with("/path/to/level_folder/config").and_return(config_file)
        Githug::Level.levels.should eq([
          nil,
          "level1",
          "level2",
          "level3"
        ])
      end
    end

    context("when there is no folder option in the profile") do
      it "retrieves the list of levels from the LEVELS constant" do
        profile = double("profile")
        profile.should_receive(:folder).and_return(nil)
        Githug::Profile.should_receive(:load).and_return(profile)
        Githug::Level.levels.should be(Githug::Level::LEVELS)
      end
    end
  end

  describe ".load_from_file" do
    it "loads the level" do
      subject.instance_variable_get("@difficulty").should eql(1)
      subject.instance_variable_get("@description").should eql("A test description")
    end

    it "return false if the level does not exist" do
      File.stub(:exists?).and_return(false)
      Githug::Level.load_from_file("/foo/bar/test/level.rb").should eql(false)
    end
  end

  describe ".setup" do

    it "returns false if the level does not exist" do
      File.stub(:exists?).and_return(false)
      Githug::Level.setup("/foo/bar/test/level.rb").should eql(false)
    end

  end


  describe "#solve" do

    it "returns false if the level requirements have not been met" do
      subject.solve.should eql(false)
    end

    it "returns true if the level requirements have been met" do
      Grit::Repo.stub(:new).and_return(true)
      subject.solve.should eql(true)
    end

  end

  describe "#test" do
    it "calls solve" do
      subject.should_receive(:_solution)
      subject.test
    end
  end


  describe "#full_description" do

    it "displays a full description" do
      Githug::UI.stub(:puts)
      Githug::UI.should_receive(:puts).with("Level: 1")
      Githug::UI.should_receive(:puts).with("Difficulty: *")
      Githug::UI.should_receive(:puts).with("A test description")
      subject.full_description
    end

  end

  describe "#setup" do

    it "calls setup" do
      repo.should_receive(:reset)
      subject.setup_level.should eql("test")
    end

    it "does not call the setup if none exists" do
      subject.instance_variable_set("@setup", nil)
      lambda {subject.setup_level}.should_not raise_error(NoMethodError)
    end

  end


  describe "#repo" do

    it "initializes a repository when repo is called" do
      subject.repo.should equal(repo)
      Githug::Repository.should_not_receive(:new)
      subject.repo.should equal(repo)
    end

  end

  describe "#hint" do

    let(:profile) { mock.as_null_object }

    before(:each) do
      profile.stub(:folder).and_return(nil)
      profile.stub(:current_hint_index).and_return(0,0,1,0)
      Githug::Profile.stub(:load).and_return(profile)
    end

    it "returns sequential hint if there are multiple" do
      subject.should_receive(:puts).ordered.with("this is hint 1")
      subject.show_hint

      subject.should_receive(:puts).ordered.with("this is hint 2")
      subject.show_hint

      subject.should_receive(:puts).ordered.with("this is hint 1")
      subject.show_hint
    end

    it "displays a hint if there are not multiple" do
      subject.instance_variable_set("@hints", nil)
      subject.should_receive(:puts).with("this is a hint")
      subject.show_hint
    end

    it "does not call the hint if none exist" do
      subject.instance_variable_set("@hint", nil)
      lambda {subject.show_hint}.should_not raise_error(NoMethodError)
    end
  end

  describe "#init_from_level" do
    it "copies the files from the level folder" do
      FileUtils.should_receive(:cp_r).with("#{subject.level_path}/.", ".")
      FileUtils.should_receive(:mv).with(".githug", ".git")
      subject.init_from_level
    end
  end
end
