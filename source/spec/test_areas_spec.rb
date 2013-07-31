require 'spec_helper'
require 'tmpdir'
require_relative File.join(File.expand_path(__FILE__), "..", "..", "test_areas")

include TestAreas

describe TestAreas do
  describe "#get_matrices" do
    it "returns an Array" do
      get_matrices(Dir.tmpdir, Dir.tmpdir, "test_area").should be_an_instance_of Array
    end

    it { get_matrices(Dir.tmpdir, Dir.tmpdir, "test_area").should be_empty }
  end

  describe "#get_rtps" do
    it "returns an Array" do
      rtp_val = {
        "test" => {
          'test_areas' => "test"
        }
      }

      get_rtps(rtp_val, Dir.tmpdir, Dir.tmpdir).should be_an_instance_of Array
    end

    it "returns the path" do
      rtp_val = {
        "test" => {
          'test_areas' => "test"
        }
      }

      arr = get_rtps(rtp_val, Dir.tmpdir, Dir.tmpdir)
      arr[0].path.should eq "test"
    end
  end
end
