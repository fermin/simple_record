require 'test/unit'
require File.join(File.dirname(__FILE__), "/../lib/simple_record")
require File.join(File.dirname(__FILE__), "./test_helpers")
require File.join(File.dirname(__FILE__), "./test_base")
require "yaml"
require 'aws'
require_relative 'models/my_model'
require_relative 'models/my_child_model'
require_relative 'models/model_with_enc'
require 'active_support'


# Pagination is intended to be just like will_paginate.
class TestPagination < TestBase

    def test_paginate
        create_my_models(20)

        i = 20
        (1..3).each do |page|
            models = MyModel.paginate :page=>page, :per_page=>5, :order=>"created desc", :consistent_read => true
            assert models.size == 5, "models.size=#{models.size}"
            models.each do |m|
                i -= 1
                puts m.name
                assert m.age == i
            end
        end
    end

end
