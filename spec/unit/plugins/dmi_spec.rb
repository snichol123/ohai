#
# Author:: Bryan McLellan (<btm@loftninjas.org>)
# Copyright:: Copyright (c) 2009 Bryan McLellan
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "spec_helper"

# NOTE: These data lines must be prefixed with one or two tabs, not spaces.
DMI_OUT = <<~EOS.freeze
  # dmidecode 2.9
  SMBIOS 2.4 present.
  98 structures occupying 3699 bytes.
  Table at 0x000E0010.

  Handle 0x0000, DMI type 0, 24 bytes
  BIOS Information
  	Vendor: Phoenix Technologies LTD
  	Version: 6.00
  	Release Date: 12/31/2009
  	Address: 0xEA2E0
  	Runtime Size: 89376 bytes
  	ROM Size: 64 kB
  	Characteristics:
  		ISA is supported
  		PCI is supported
  		PC Card (PCMCIA) is supported
  		PNP is supported
  		APM is supported
  		BIOS is upgradeable
  		BIOS shadowing is allowed
  		ESCD support is available
  		USB legacy is supported
  		Smart battery is supported
  		BIOS boot specification is supported
  		Targeted content distribution is supported
  	BIOS Revision: 4.6
  	Firmware Revision: 0.0

  Handle 0x0001, DMI type 1, 27 bytes
  System Information
  	Manufacturer: VMware, Inc.
  	Product Name: VMware Virtual Platform
  	Version: None
  	Serial Number: VMware-56 4d 71 d1 65 70 83 a8-df c8 14 12 19 41 71 45
  	UUID: 564D71D1-6570-83A8-DFC8-141219417145
  	Wake-up Type: Power Switch
  	SKU Number: Not Specified
  	Family: Not Specified

  Handle 0x0002, DMI type 2, 15 bytes
  Base Board Information
  	Manufacturer: Intel Corporation
  	Product Name: 440BX Desktop Reference Platform
  	Version: None
  	Serial Number: None
  	Asset Tag: Not Specified
  	Features: None
  	Location In Chassis: Not Specified
  	Chassis Handle: 0x0000
  	Type: Unknown
  	Contained Object Handles: 0

  Handle 0x1000, DMI type 16, 15 bytes
  Physical Memory Array
  	Location: Other
  	Use: System Memory
  	Error Correction Type: Multi-bit ECC
  	Maximum Capacity: 2 GB
  	Error Information Handle: Not Provided
  	Number Of Devices: 1

  Handle 0x0003, DMI type 3, 21 bytes
  Chassis Information
  	Manufacturer: No Enclosure
  	Type: Other
  	Lock: Not Present
  	Version: N/A
  	Serial Number: None
  	Asset Tag: No Asset Tag
  	Boot-up State: Safe
  	Power Supply State: Safe
  	Thermal State: Safe
  	Security Status: None
  	OEM Information: 0x00001234
  	Height: Unspecified
  	Number Of Power Cords: Unspecified
  	Contained Elements: 0
EOS

describe Ohai::System, "plugin dmi" do
  let(:plugin) { get_plugin("dmi") }
  let(:stdout) { DMI_OUT }

  before do
    allow(plugin).to receive(:shell_out).with("dmidecode").and_return(mock_shell_out(0, stdout, ""))
  end

  it "runs dmidecode" do
    expect(plugin).to receive(:shell_out).with("dmidecode").and_return(mock_shell_out(0, stdout, ""))
    plugin.run
  end

  # Test some simple sample data
  {
    bios: {
      vendor: "Phoenix Technologies LTD",
      release_date: "12/31/2009",
    },
    system: {
      manufacturer: "VMware, Inc.",
      product_name: "VMware Virtual Platform",
    },
    chassis: {
      lock: "Not Present",
      asset_tag: "No Asset Tag",
    },
  }.each do |id, data|
    data.each do |attribute, value|
      it "attribute [:dmi][:#{id}][:#{attribute}] is set" do
        plugin.run
        expect(plugin[:dmi][id][attribute]).to eql(value)
      end
      it "attribute [:dmi][:#{id}][:#{attribute}] set for windows output" do
        stdout = convert_windows_output(DMI_OUT)
        expect(plugin).to receive(:shell_out).with("dmidecode").and_return(mock_shell_out(0, stdout, ""))
        plugin.run
        expect(plugin[:dmi][id][attribute]).to eql(value)
      end
    end
  end

  it "allows capturing additional DMI data" do
    Ohai.config[:additional_dmi_ids] = [ 16 ]
    plugin.run
    expect(plugin[:dmi]).to have_key(:physical_memory_array)
  end

  it "correctly ignores data in excluded DMI IDs" do
    expect(plugin).to receive(:shell_out).with("dmidecode").and_return(mock_shell_out(0, stdout, ""))
    plugin.run
    expect(plugin[:dmi]).not_to have_key(:physical_memory_array)
  end
end
