require 'spec_helper'
require 'tmpdir'
require_relative File.join(File.expand_path(__FILE__), "..", "..", "test_areas")

include TestAreas

describe TestAreas do
  describe "#get_matrices" do
    it "returns an Array" do
      matrices = get_matrices(Dir.tmpdir, Dir.tmpdir, "test_area")

      expect(matrices).to be_an_instance_of Array
      expect(matrices).to be_empty
    end
  end

  describe "#get_rtps" do
    it "returns an Array" do
      rtp_val = {
        "test" => {
          'test_areas' => "test"
        }
      }

      rtps = get_rtps(rtp_val, Dir.tmpdir, Dir.tmpdir)
      expect(rtps).to be_an_instance_of Array
    end

    it "returns the path" do
      rtp_val = {
        "test" => {
          'test_areas' => "test"
        }
      }

      arr = get_rtps(rtp_val, Dir.tmpdir, Dir.tmpdir)
      expect(arr[0].path).to eq "test"
    end
  end
end
