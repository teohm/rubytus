require 'test_helper'
require 'rubytus/storage'
require 'rubytus/setup'

class TestStorage < MiniTest::Test
  include Rubytus::Mock
  include Rubytus::Setup

  def setup
    @data_dir = data_dir

    @options = {
      :data_dir  => @data_dir,
      :base_path => '/uploads/'
    }

    @read_only_options = {
      :data_dir  => "/opt/rubytus",
      :base_path => '/uploads/'
    }

    validate_data_dir(@data_dir)

    @uid   = uid
    @storage = Rubytus::Storage.new(@options)
  end

  def teardown
    remove_data_dir
  end

  def test_file_path
    assert_match "#{@uid}.bin", @storage.file_path(@uid)
  end

  def test_info_path
    assert_match "#{@uid}.info", @storage.info_path(@uid)
  end

  def test_create_file
    @storage.create_file(@uid, :final_length => 512)
    assert File.exist?(@storage.file_path(@uid))
    assert File.exist?(@storage.info_path(@uid))
  end

  def test_write_file_failed
    storage = Rubytus::Storage.new(@read_only_options)
    assert_raises(Rubytus::PermissionError) { storage.create_file(@uid, :final_length => 512) }
  end

  def test_read_info
    File.open(@storage.info_path(@uid), 'w') do |f|
      f.write('{"Offset":100,"FinalLength":500,"Meta":null}')
    end

    info = @storage.read_info(@uid)
    assert_kind_of Hash, info
    assert_equal 100, info['Offset']
  end

  def test_read_info_failure
    storage = Rubytus::Storage.new(@read_only_options)
    assert_raises(Rubytus::PermissionError) { storage.read_info(@uid) }
  end

  def test_update_info
    File.open(@storage.info_path(@uid), 'w') do |f|
      f.write('{"Offset":100,"FinalLength":500,"Meta":null}')
    end

    @storage.update_info(@uid, 'Offset' => 250)

    info = @storage.read_info(@uid)
    assert_kind_of Hash, info
    assert_equal 250, info['Offset']
  end

  def test_update_info_failure
    storage = Rubytus::Storage.new(@read_only_options)
    assert_raises(Rubytus::PermissionError) { storage.update_info(@uid, 'Offset' => 250) }
  end

  def test_read_file
    File.open(@storage.file_path(@uid), 'w') do |f|
      f.write('1234567')
    end

    assert_equal '1234567', @storage.read_file(@uid)
  end

  def test_read_file_failure
    storage = Rubytus::Storage.new(@read_only_options)
    assert_raises(Rubytus::PermissionError) { storage.read_file(@uid) }
  end
end