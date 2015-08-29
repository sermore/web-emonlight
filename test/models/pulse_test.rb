require 'test_helper'

class PulseTest < ActiveSupport::TestCase
	self.use_transactional_fixtures = true

#	test "node one" do
#		assert_equal(1000, Pulse.where(node: Node.find_by_title(:one)).count())
#		assert_equal(1001, Pulse.where(node: Node.find_by_title(:two)).count())
#	end

	test "hourly mean" do
		assert_equal(60.0, Pulse.hourly_mean(Node.find_by_title(:fixed60)))
		assert_equal(45.0, Pulse.hourly_mean(Node.find_by_title(:fixed60), '2015-05-01 00:00', '2015-05-01 1:30'))
		assert_equal(60.0, Pulse.hourly_mean(Node.find_by_title(:fixed60), '2015-05-01 00:00', '2015-05-01 12:00'))
		assert_in_delta(41.1764705882352941, Pulse.hourly_mean(Node.find_by_title(:wday)))
		assert_equal(40.0, Pulse.hourly_mean(Node.find_by_title(:wday), '2015-05-01', '2015-05-15'))
		assert_equal(1030.0, Pulse.hourly_mean(Node.find_by_title(:hourly), '2015-05-01 03:00', '2015-05-01 04:00'))
		assert_equal(1115.0, Pulse.hourly_mean(Node.find_by_title(:hourly), '2015-05-01 00:00', '2015-05-02 00:00'))
	end

	test "daily mean" do
		assert_equal(1440.0, Pulse.daily_mean(Node.find_by_title(:fixed60)))
		assert_equal(1440.0, Pulse.daily_mean(Node.find_by_title(:fixed60), '2015-05-01', '2015-05-02'))
		assert_equal(720.0, Pulse.daily_mean(Node.find_by_title(:fixed60), '2015-05-01 00:00', '2015-05-01 12:00'))
		assert_in_delta(988.235294118, Pulse.daily_mean(Node.find_by_title(:wday)))
		assert_equal(960.0, Pulse.daily_mean(Node.find_by_title(:wday), '2015-05-01', '2015-05-15'))
	end

	test "monthly mean" do
		assert_equal(12960.0, Pulse.monthly_mean(Node.find_by_title(:fixed60)))
		assert_equal(47520.0, Pulse.monthly_mean(Node.find_by_title(:monthly)))
		assert_equal(44640.0, Pulse.monthly_mean(Node.find_by_title(:monthly), '2015-05-01', '2015-06-01'))
	end

	test "yearly mean" do
		assert_equal(12960.0, Pulse.yearly_mean(Node.find_by_title(:fixed60)))
		assert_equal(95040.0, Pulse.yearly_mean(Node.find_by_title(:monthly)))
		assert_equal(44640.0, Pulse.yearly_mean(Node.find_by_title(:monthly), '2015-05-01', '2015-06-01'))
	end

	test "weekly" do
		assert_equal([["Sunday   ", 1440.0], ["Monday   ", 1440.0], ["Tuesday  ", 1440.0], ["Wednesday", 1440.0], ["Thursday ", 1440.0], ["Friday   ", 1440.0], ["Saturday ", 1440.0]], Pulse.weekly(Node.find_by_title(:fixed60)))
		assert_equal([["Sunday   ", 1440.0], ["Friday   ", 1440.0], ["Saturday ", 1440.0]], Pulse.weekly(Node.find_by_title(:fixed60), '2015-05-01', '2015-05-04'))
		assert_equal([["Sunday   ", 240.0], ["Monday   ", 480.0], ["Tuesday  ", 720.0], ["Wednesday", 960.0], ["Thursday ", 1200.0], ["Friday   ", 1440.0], ["Saturday ", 1680.0]], Pulse.weekly(Node.find_by_title(:wday)))
		assert_equal([["Sunday   ", 240.0], ["Monday   ", 480.0], ["Tuesday  ", 720.0], ["Wednesday", 960.0], ["Thursday ", 1200.0], ["Friday   ", 1440.0], ["Saturday ", 1680.0]], Pulse.weekly(Node.find_by_title(:wday), '2015-05-01', '2015-05-08'))
	end

	test "daily" do
		assert_equal([[0.0, 60.0], [1.0, 60.0], [2.0, 60.0], [3.0, 60.0], [4.0, 60.0], [5.0, 60.0], [6.0, 60.0], [7.0, 60.0], [8.0, 60.0], [9.0, 60.0], [10.0, 60.0], [11.0, 60.0], [12.0, 60.0], [13.0, 60.0], [14.0, 60.0], [15.0, 60.0], [16.0, 60.0], [17.0, 60.0], [18.0, 60.0], [19.0, 60.0], [20.0, 60.0], [21.0, 60.0], [22.0, 60.0], [23.0, 60.0]], Pulse.daily(Node.find_by_title(:fixed60)))
		assert_equal([[7.0, 60.0], [8.0, 60.0], [9.0, 60.0], [10.0, 60.0], [11.0, 60.0], [12.0, 60.0], [13.0, 60.0], [14.0, 60.0]], Pulse.daily(Node.find_by_title(:fixed60), '2015-05-01 07:00', '2015-05-01 15:00'))
		assert_equal([[0.0, 41.1764705882353], [1.0, 41.1764705882353], [2.0, 41.1764705882353], [3.0, 41.1764705882353], [4.0, 41.1764705882353], [5.0, 41.1764705882353], [6.0, 41.1764705882353], [7.0, 41.1764705882353], [8.0, 41.1764705882353], [9.0, 41.1764705882353], [10.0, 41.1764705882353], [11.0, 41.1764705882353], [12.0, 41.1764705882353], [13.0, 41.1764705882353], [14.0, 41.1764705882353], [15.0, 41.1764705882353], [16.0, 41.1764705882353], [17.0, 41.1764705882353], [18.0, 41.1764705882353], [19.0, 41.1764705882353], [20.0, 41.1764705882353], [21.0, 41.1764705882353], [22.0, 41.1764705882353], [23.0, 41.1764705882353]], Pulse.daily(Node.find_by_title(:wday)))
		assert_equal([[0.0, 1000.0], [1.0, 1010.0], [2.0, 1020.0], [3.0, 1030.0], [4.0, 1040.0], [5.0, 1050.0], [6.0, 1060.0], [7.0, 1070.0], [8.0, 1080.0], [9.0, 1090.0], [10.0, 1100.0], [11.0, 1110.0], [12.0, 1120.0], [13.0, 1130.0], [14.0, 1140.0], [15.0, 1150.0], [16.0, 1160.0], [17.0, 1170.0], [18.0, 1180.0], [19.0, 1190.0], [20.0, 1200.0], [21.0, 1210.0], [22.0, 1220.0], [23.0, 1230.0]], Pulse.daily(Node.find_by_title(:hourly), '2015-05-01', '2015-05-02'))
		assert_equal([[0.0, 1000.0], [1.0, 1010.0], [2.0, 1020.0], [3.0, 1030.0], [4.0, 1040.0], [5.0, 1050.0], [6.0, 1060.0], [7.0, 1070.0], [8.0, 1080.0], [9.0, 1090.0], [10.0, 1100.0], [11.0, 1110.0], [12.0, 1120.0], [13.0, 1130.0], [14.0, 1140.0], [15.0, 1150.0], [16.0, 1160.0], [17.0, 1170.0], [18.0, 1180.0], [19.0, 1190.0], [20.0, 1200.0], [21.0, 1210.0], [22.0, 1220.0], [23.0, 1230.0]], Pulse.daily(Node.find_by_title(:hourly)))
	end

	test "monthly" do
		assert_equal([[1.0, 1440.0], [2.0, 1440.0], [3.0, 1440.0], [4.0, 1440.0], [5.0, 1440.0], [6.0, 1440.0], [7.0, 1440.0], [8.0, 1440.0], [9.0, 1440.0]], Pulse.monthly(Node.find_by_title(:fixed60)))
		assert_equal([[1.0, 1440.0], [2.0, 1440.0], [3.0, 1440.0], [4.0, 1440.0], [5.0, 1440.0], [6.0, 1440.0], [7.0, 1440.0], [8.0, 1440.0], [9.0, 1440.0], [10.0, 1440.0], [11.0, 1440.0], [12.0, 1440.0], [13.0, 1440.0], [14.0, 1440.0], [15.0, 1440.0], [16.0, 1440.0], [17.0, 1440.0], [18.0, 1440.0], [19.0, 1440.0], [20.0, 1440.0], [21.0, 1440.0], [22.0, 1440.0], [23.0, 1440.0], [24.0, 1440.0], [25.0, 1440.0], [26.0, 1440.0], [27.0, 1440.0], [28.0, 1440.0], [29.0, 1440.0], [30.0, 1440.0], [31.0, 1440.0]], Pulse.monthly(Node.find_by_title(:monthly), '2015-05-01', '2015-06-01'))
		assert_equal([[1.0, 1560.0], [2.0, 1560.0], [3.0, 1560.0], [4.0, 1560.0], [5.0, 1560.0], [6.0, 1560.0], [7.0, 1560.0], [8.0, 1560.0], [9.0, 1560.0], [10.0, 1560.0], [11.0, 1560.0], [12.0, 1560.0], [13.0, 1560.0], [14.0, 1560.0], [15.0, 1560.0], [16.0, 1560.0], [17.0, 1560.0], [18.0, 1560.0], [19.0, 1560.0], [20.0, 1560.0], [21.0, 1560.0], [22.0, 1560.0], [23.0, 1560.0], [24.0, 1560.0], [25.0, 1560.0], [26.0, 1560.0], [27.0, 1560.0], [28.0, 1560.0], [29.0, 1560.0], [30.0, 1560.0], [31.0, 1440.0]], Pulse.monthly(Node.find_by_title(:monthly)))
	end

	test "yearly" do
		assert_equal([["May      ", 12960.0]], Pulse.yearly(Node.find_by_title(:fixed60)))
		assert_equal([["May      ", 44640.0]], Pulse.yearly(Node.find_by_title(:monthly), '2015-05-01', '2015-06-01'))
		assert_equal([["May      ", 44640.0], ["June     ", 50400.0]], Pulse.yearly(Node.find_by_title(:monthly)))
	end

end
