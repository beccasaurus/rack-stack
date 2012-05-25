require "rspec"
require "rack/test"
require "rack/stack"
require "artifice"

require File.dirname(__FILE__) + "/../mock_apps/mock_dog_api"
require File.dirname(__FILE__) + "/../mock_apps/mock_cat_api"
require File.dirname(__FILE__) + "/../dogs_and_cats"
