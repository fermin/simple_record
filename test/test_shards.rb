require 'test/unit'
require File.join(File.dirname(__FILE__), "/../lib/simple_record")
require File.join(File.dirname(__FILE__), "./test_helpers")
require File.join(File.dirname(__FILE__), "./test_base")
require "yaml"
require 'aws'
require_relative 'models/my_sharded_model'

# Tests for SimpleRecord
#
class TestShards < TestBase

  def setup
    super
#    delete_all MyShardedModel
#    delete_all MyShardedByFieldModel
  end

  def teardown
    super

  end

  # We'll want to shard based on ID's, user decides how many shards and some mapping function will
  # be used to select the shard.
  def test_id_sharding

    puts 'test_id_sharding start'
    ob_count = 1000

    mm = MyShardedModel.new(:name=>"single")
    mm.save
    sleep 1
    puts 'finding by id'
    mm2 = MyShardedModel.find(mm.id)
    p mm2
    assert_equal mm.id, mm2.id
    puts 'deleting'
    mm2.delete
    sleep 1
    mm3 = MyShardedModel.find(mm.id)
    assert_nil mm3

    puts "saving #{ob_count} now"
    saved = []
    ob_count.times do |i|
      mm = MyShardedModel.new(:name=>"name #{i}")
      mm.save
      saved << mm
    end
    sleep 2

    # todo: assert that we're actually sharding

    puts "finding them all sequentially"
    start_time = Time.now
    found = []
    rs = MyShardedModel.find(:all, :per_token=>2500)
    rs.each do |m|
#      p m
      found << m
    end
    duration = Time.now.to_f - start_time.to_f
    puts 'Find sequential duration=' + duration.to_s
    puts 'size=' + found.size.to_s
    saved.each do |so|
      assert(found.find { |m1| m1.id == so.id })
    end


    puts "Now let's try concurrently"
    start_time = Time.now
    found = []
    rs = MyShardedModel.find(:all, :concurrent=>true, :per_token=>2500)
    rs.each do |m|
#      p m
      found << m
    end
    concurrent_duration = Time.now.to_f - start_time.to_f
    puts 'Find concurrent duration=' + concurrent_duration .to_s
    puts 'size=' + found.size.to_s
    saved.each do |so|
      assert(found.find { |m1| m1.id == so.id })
    end

    assert concurrent_duration < duration

    puts "deleting all of them"
    found.each do |fo|
      fo.delete
    end

    sleep 2

    puts "Now ensure that all are deleted"
    rs = MyShardedModel.find(:all)
    assert rs.size == 0

    puts "Testing belongs_to sharding"

  end


  def test_field_sharding

    states = MyShardedByFieldModel.shards
    puts "states=" + states.inspect

    mm = MyShardedByFieldModel.new(:name=>"single", :state=>"CA")
    mm.save
    sleep 1
    puts 'finding by id'
    mm2 = MyShardedByFieldModel.find(mm.id)
    p mm2
    assert_equal mm.id, mm2.id
    puts 'deleting'
    mm2.delete
    sleep 1
    mm3 = MyShardedByFieldModel.find(mm.id)
    assert_nil mm3

    puts "saving 20 now"
    saved = []
    20.times do |i|
      mm = MyShardedByFieldModel.new(:name=>"name #{i}", :state=>states[i % states.size])
      mm.save
      p mm
      saved << mm
    end

    sleep 1
    # todo: assert that we're actually sharding

    puts "finding them all"
    found = []
    rs = MyShardedByFieldModel.find(:all)
    rs.each do |m|
      p m
      found << m
    end
    saved.each do |so|
      assert(found.find { |m1| m1.id == so.id })
    end

    rs = MyShardedByFieldModel.find(:all)
    rs.each do |m|
      p m
      found << m
    end
    saved.each do |so|
      assert(found.find { |m1| m1.id == so.id })
    end

    # Try to find on a specific known shard
    selects = SimpleRecord.stats.selects
    cali_models = MyShardedByFieldModel.find(:all, :shard => "CA")
    puts 'cali_models=' + cali_models.inspect
    assert_equal(5, cali_models.size)
    assert_equal(selects + 1, SimpleRecord.stats.selects)

    puts "deleting all of them"
    found.each do |fo|
      fo.delete
    end
    sleep 1

    puts "Now ensure that all are deleted"
    rs = MyShardedByFieldModel.find(:all)
    assert rs.size == 0
  end

  def test_time_sharding

  end

end
