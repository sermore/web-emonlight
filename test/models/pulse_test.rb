require 'test_helper'

class PulseTest < ActiveSupport::TestCase
	self.use_transactional_fixtures = true

#	test "node one" do
#		assert_equal(1000, Pulse.where(node: Node.find_by_title(:one)).count())
#		assert_equal(1001, Pulse.where(node: Node.find_by_title(:two)).count())
#	end

	test "tz" do
		Time.zone = "Pacific/Midway"
		assert_equal("extract(hour from timezone('-11:00', pulse_time))::integer", Pulse.GROUPING(0))
		Time.zone = "Europe/Rome"
		assert_equal("extract(hour from timezone('+01:00', pulse_time))::integer", Pulse.GROUPING(0))
		Time.zone = "UTC"
	end

	test "raw mean" do
		assert_equal([1440.0, 1], Pulse._raw_mean(Node.find_by_title(:fixed60), StatService::DAILY, Pulse.convert_date('2015-05-01'), Pulse.convert_date('2015-05-02')))
		assert_equal([1440.0, 1], Pulse._raw_mean(Node.find_by_title(:wday), StatService::DAILY, Pulse.convert_date('2015-05-01'), Pulse.convert_date('2015-05-02')))
		assert_equal([1560.0, 2], Pulse._raw_mean(Node.find_by_title(:wday), StatService::DAILY, Pulse.convert_date('2015-05-01'), Pulse.convert_date('2015-05-03')))
		assert_equal([1120.0, 3], Pulse._raw_mean(Node.find_by_title(:wday), StatService::DAILY, Pulse.convert_date('2015-05-01'), Pulse.convert_date('2015-05-04')))
		assert_equal([960.0, 4], Pulse._raw_mean(Node.find_by_title(:wday), StatService::DAILY, Pulse.convert_date('2015-05-01'), Pulse.convert_date('2015-05-05')))
	end

	test "mean" do
		assert_equal(0.0, Pulse.mean(Node.find_by_title(:fixed60), StatService::DAILY, '2015-04-01'))
		assert_equal(1440.0, Pulse.mean(Node.find_by_title(:fixed60), StatService::DAILY, '2015-05-02'))
		assert_equal(1440.0, Pulse.mean(Node.find_by_title(:fixed60), StatService::DAILY, '2015-05-03'))
		assert_equal(1440.0, Pulse.mean(Node.find_by_title(:fixed60), StatService::DAILY, '2015-05-04 12:00'))
		assert_equal(1440.0, Pulse.mean(Node.find_by_title(:fixed60), StatService::DAILY, '2015-05-05'))
		assert_throws(:mean_fails) { Pulse.mean(Node.find_by_title(:fixed60), StatService::DAILY, '2015-05-03 08:00') }
		# test for simple period 1/5 => 60, 2/5 => 70, 3/5 => 10, ...
		assert_equal(1440.0, Pulse.mean(Node.find_by_title(:wday), StatService::DAILY, '2015-05-02'))
		assert_equal(1560.0, Pulse.mean(Node.find_by_title(:wday), StatService::DAILY, '2015-05-03'))
	end

	test "mean_on_period" do
		# test for period not available
		assert_equal(0, Pulse.mean(Node.find_by_title(:fixed60), StatService::DAILY, '2015-04-01', 5))
		# test for simple period
		assert_equal(1440.0, Pulse.mean(Node.find_by_title(:fixed60), StatService::DAILY, '2015-05-02', 5))
		# incremental calculation from same start time
		assert_equal(1440.0, Pulse.mean(Node.find_by_title(:fixed60), StatService::DAILY, '2015-05-03', 5))
		assert_equal(1440.0, Pulse.mean(Node.find_by_title(:fixed60), StatService::DAILY, '2015-05-04 12:00', 5))
		# incremental calculation with different start time
		assert_equal(1440.0, Pulse.mean(Node.find_by_title(:fixed60), StatService::DAILY, '2015-05-8', 5))
		# try to calculate a previous period
		assert_throws(:mean_fails) { Pulse.mean(Node.find_by_title(:fixed60), StatService::DAILY, '2015-05-03 08:00', 5) }
		# test for simple period 1/5 => 60, 2/5 => 70, 3/5 => 10, ...
		assert_equal(1440.0, Pulse.mean(Node.find_by_title(:wday), StatService::DAILY, '2015-05-02', 5))
		assert_equal(1560.0, Pulse.mean(Node.find_by_title(:wday), StatService::DAILY, '2015-05-03', 5))
		# test for simple period, discard previous calculation
		assert_equal(720.0, Pulse.mean(Node.find_by_title(:wday), StatService::DAILY, '2015-05-08', 5))
	end

	test "hourly mean" do
		assert_equal(60.0, Pulse.hourly_mean(Node.find_by_title(:fixed60), '2015-05-01 1:30'))
		assert_equal(60.0, Pulse.hourly_mean(Node.find_by_title(:fixed60), '2015-05-01 12:00'))
		assert_in_delta(60.0, Pulse.hourly_mean(Node.find_by_title(:fixed60), '2015-05-05'))
		assert_equal(40.0, Pulse.hourly_mean(Node.find_by_title(:wday), '2015-05-15'))
		assert_in_delta(41.18411375337093, Pulse.hourly_mean(Node.find_by_title(:wday), '2015-05-18'))
		assert_equal(1015.0, Pulse.hourly_mean(Node.find_by_title(:hourly), '2015-05-01 04:00', 1))
		assert_equal(1115.0, Pulse.hourly_mean(Node.find_by_title(:hourly), '2015-05-02 00:00'))
	end

	test "daily mean" do
		assert_equal(1440.0, Pulse.daily_mean(Node.find_by_title(:fixed60), '2015-05-01 12:00'))
		assert_equal(1440.0, Pulse.daily_mean(Node.find_by_title(:fixed60), '2015-05-02'))
		assert_equal(1440.0, Pulse.daily_mean(Node.find_by_title(:fixed60), '2015-05-02 21:00', 1))
		assert_equal(1440.0, Pulse.daily_mean(Node.find_by_title(:fixed60), '2015-05-10'))
		assert_equal(960.0, Pulse.daily_mean(Node.find_by_title(:wday), '2015-05-15'))
		assert_in_delta(988.4187300809022, Pulse.daily_mean(Node.find_by_title(:wday), '2015-05-18'))
	end

	test "monthly mean" do
		assert_in_delta(14400.0, Pulse.monthly_mean(Node.find_by_title(:fixed20), '2015-02-15'))
		# assert_equal(47520.0, Pulse.monthly_mean(Node.find_by_title(:monthly)))
		assert_equal(14400.0, Pulse.monthly_mean(Node.find_by_title(:fixed20), '2015-02-04', 60))
		assert_equal(46740.95296932954, Pulse.monthly_mean(Node.find_by_title(:monthly), '2015-07-01', 90))
	end

	test "yearly mean" do
		assert_equal(525600.0, Pulse.yearly_mean(Node.find_by_title(:fixed60), '2015-05-10'))
		assert_equal(568681.5944601761, Pulse.yearly_mean(Node.find_by_title(:monthly), '2015-07-01'))
		assert_equal(525600.0, Pulse.yearly_mean(Node.find_by_title(:monthly), '2015-06-01', 40))
	end

	test "daily" do
		# single interval, start from beginning
		assert_equal([[0, 60.0, 3.0], [1, 60.0, 3.0], [2, 60.0, 3.0], [3, 60.0, 3.0], [4, 60.0, 3.0], [5, 60.0, 3.0], [6, 60.0, 3.0], [7, 60.0, 3.0], [8, 60.0, 3.0], [9, 60.0, 3.0], [10, 60.0, 3.0], [11, 60.0, 3.0], [12, 59.99999999999999, 2.416666666666667], [13, 60.0, 2.0], [14, 60.0, 2.0], [15, 60.0, 2.0], [16, 60.0, 2.0], [17, 60.0, 2.0], [18, 60.0, 2.0], [19, 60.0, 2.0], [20, 60.0, 2.0], [21, 60.0, 2.0], [22, 60.0, 2.0], [23, 60.0, 2.0]], Pulse.daily(Node.find_by_title(:fixed60), '2015-05-03 12:25:14', 4).map {|k,v| [k, v.mean, v.sum_weight]})
		# concatenate to previous result, no removing
		assert_equal([[0, 60.0, 4.0], [1, 60.0, 4.0], [2, 60.0, 4.0], [3, 60.0, 4.0], [4, 60.0, 4.0], [5, 60.0, 4.0], [6, 60.0, 4.0], [7, 60.0, 4.0], [8, 60.0, 4.0], [9, 60.0, 4.0], [10, 60.0, 4.0], [11, 60.0, 3.0], [12, 59.99999999999999, 3.0000000000000036], [13, 60.0, 3.0], [14, 60.0, 3.0], [15, 60.0, 3.0], [16, 60.0, 3.0], [17, 60.0, 3.0], [18, 60.0, 3.0], [19, 60.0, 3.0], [20, 60.0, 3.0], [21, 60.0, 3.0], [22, 60.0, 3.0], [23, 60.0, 3.0]], Pulse.daily(Node.find_by_title(:fixed60), '2015-05-04 11:00', 4).map {|k,v| [k, v.mean, v.sum_weight]})
		# reuse previous results
		assert_equal([[0, 60.0, 4.0], [1, 60.0, 4.0], [2, 60.0, 4.0], [3, 60.0, 4.0], [4, 60.0, 4.0], [5, 60.0, 4.0], [6, 60.0, 4.0], [7, 60.0, 4.0], [8, 60.0, 4.0], [9, 60.0, 4.0], [10, 60.0, 4.0], [11, 60.0, 3.0], [12, 60.0, 3.0], [13, 60.0, 3.0], [14, 60.0, 3.0], [15, 60.0, 3.0], [16, 60.0, 3.0], [17, 60.0, 3.0], [18, 60.0, 3.0], [19, 60.0, 3.0], [20, 60.0, 3.0], [21, 60.0, 3.0], [22, 60.0, 3.0], [23, 60.0, 3.0]], Pulse.daily(Node.find_by_title(:fixed60), '2015-05-04 11:00:59', 4).map {|k,v| [k, v.mean, v.sum_weight]})
		# concatenate to previous result, removing initial interval
		assert_equal([[0, 60.0, 4.0], [1, 60.0, 4.0], [2, 60.0, 4.0], [3, 60.0, 4.0], [4, 60.0, 4.0], [5, 60.0, 4.0], [6, 60.0, 4.0], [7, 60.0, 4.0], [8, 60.0, 4.0], [9, 60.0, 4.0], [10, 60.0, 4.0], [11, 60.0, 4.0], [12, 60.0, 4.0], [13, 60.0, 4.0], [14, 60.0, 4.0], [15, 60.0, 4.0], [16, 60.0, 4.0], [17, 60.0, 4.0], [18, 60.0, 4.0], [19, 60.0, 4.0], [20, 60.0, 4.0], [21, 60.0, 4.0], [22, 60.0, 4.0], [23, 60.0, 4.0]], Pulse.daily(Node.find_by_title(:fixed60), '2015-05-06 07:46', 4).map {|k,v| [k, v.mean, v.sum_weight]})
		# single interval, start from beginning, day incomplete
		assert_equal([[0, 60.0, 1.0], [1, 60.0, 1.0], [2, 60.0, 1.0], [3, 60.0, 1.0], [4, 60.0, 1.0], [5, 60.0, 1.0], [6, 60.0, 1.0], [7, 60.0, 1.0], [8, 60.0, 1.0], [9, 60.0, 1.0], [10, 60.0, 1.0], [11, 60.0, 1.0], [12, 60.0, 1.0], [13, 60.0, 1.0], [14, 60.0, 1.0], [15, 0.0, 0.0], [16, 0.0, 0.0], [17, 0.0, 0.0], [18, 0.0, 0.0], [19, 0.0, 0.0], [20, 0.0, 0.0], [21, 0.0, 0.0], [22, 0.0, 0.0], [23, 0.0, 0.0]], Pulse.daily(Node.find_by_title(:fixed60), '2015-05-01 15:00:59', 1).map {|k,v| [k, v.mean, v.sum_weight]})
		# discard previous result
		assert_equal([[0, 60.0, 1.0], [1, 60.0, 1.0], [2, 60.0, 1.0], [3, 60.0, 1.0], [4, 60.0, 1.0], [5, 60.0, 1.0], [6, 60.0, 1.0], [7, 60.0, 1.0], [8, 60.0, 1.0], [9, 60.0, 1.0], [10, 60.0, 1.0], [11, 60.0, 1.0], [12, 60.0, 1.0], [13, 60.0, 1.0], [14, 60.0, 1.0], [15, 60.0, 1.0], [16, 60.0, 1.0], [17, 59.99999999999999, 0.9833333333333334], [18, 60.0, 1.0], [19, 60.0, 1.0], [20, 60.0, 1.0], [21, 60.0, 1.0], [22, 60.0, 1.0], [23, 60.0, 1.0]], Pulse.daily(Node.find_by_title(:fixed60), '2015-05-03 17:00:59', 1).map {|k,v| [k, v.mean, v.sum_weight]})
		# single interval, no period, start from beginning
		assert_equal([[0, 60.0, 3.0], [1, 60.0, 3.0], [2, 60.0, 3.0], [3, 60.0, 3.0], [4, 60.0, 3.0], [5, 60.0, 3.0], [6, 60.0, 3.0], [7, 60.0, 3.0], [8, 60.0, 3.0], [9, 60.0, 3.0], [10, 60.0, 3.0], [11, 60.0, 3.0], [12, 60.0, 3.0], [13, 60.0, 3.0], [14, 60.0, 3.0], [15, 60.0, 3.0], [16, 60.0, 3.0], [17, 60.0, 2.0], [18, 60.0, 2.0], [19, 60.0, 2.0], [20, 60.0, 2.0], [21, 60.0, 2.0], [22, 60.0, 2.0], [23, 60.0, 2.0]], Pulse.daily(Node.find_by_title(:fixed60), '2015-05-03 17:00:59').map {|k,v| [k, v.mean, v.sum_weight]})
		# concatenate to previous result, no period, no removing
		assert_equal([[0, 60.0, 3.0], [1, 60.0, 3.0], [2, 60.0, 3.0], [3, 60.0, 3.0], [4, 60.0, 3.0], [5, 60.0, 3.0], [6, 60.0, 3.0], [7, 60.0, 3.0], [8, 60.0, 3.0], [9, 60.0, 3.0], [10, 60.0, 3.0], [11, 60.0, 3.0], [12, 60.0, 3.0], [13, 60.0, 3.0], [14, 60.0, 3.0], [15, 60.0, 3.0], [16, 60.0, 3.0], [17, 60.0, 3.0], [18, 60.0, 3.0], [19, 60.0, 3.0], [20, 60.0, 3.0], [21, 60.0, 3.0], [22, 60.0, 2.283333333333333], [23, 60.0, 2.0]], Pulse.daily(Node.find_by_title(:fixed60), '2015-05-03 22:17:59').map {|k,v| [k, v.mean, v.sum_weight]})
		assert_equal([[0, 1000.0, 2.0], [1, 1010.0, 2.0], [2, 1020.0, 2.0], [3, 1030.0, 2.0], [4, 1040.0, 2.0], [5, 1050.0602651667336, 1.3827777777777777], [6, 1060.0, 1.0], [7, 1070.0, 1.0], [8, 1080.0, 1.0], [9, 1090.0, 1.0], [10, 1100.0, 1.0], [11, 1110.0, 1.0], [12, 1120.0, 1.0], [13, 1130.0, 1.0], [14, 1140.0, 1.0], [15, 1150.0, 1.0], [16, 1160.0, 1.0], [17, 1170.0, 1.0], [18, 1180.0, 1.0], [19, 1190.0, 1.0], [20, 1200.0, 1.0], [21, 1210.0, 1.0], [22, 1220.0, 1.0], [23, 1230.0, 1.0]], Pulse.daily(Node.find_by_title(:hourly), '2015-05-02 05:23',3).map {|k,v| [k, v.mean, v.sum_weight]})
		# concatenate to previous result, removing initial interval		
		assert_equal([[0, 1000.0, 3.0], [1, 1010.0, 3.0], [2, 1020.0, 3.0], [3, 1030.0, 3.0], [4, 1040.0, 3.0], [5, 1049.9999999999984, 3.0000000000000027], [6, 1060.0, 3.0], [7, 1070.0, 3.0], [8, 1080.0, 3.0], [9, 1090.0, 3.0], [10, 1100.0, 3.0], [11, 1110.0, 3.0], [12, 1120.0, 3.0], [13, 1130.0, 3.0], [14, 1140.0, 3.0], [15, 1150.0, 3.0], [16, 1160.0, 3.0], [17, 1170.0, 3.0], [18, 1180.0, 3.0], [19, 1190.0, 3.0], [20, 1200.0, 3.0], [21, 1210.0, 3.0], [22, 1220.0, 3.0], [23, 1230.0, 3.0]], Pulse.daily(Node.find_by_title(:hourly), '2015-05-05', 3).map {|k,v| [k, v.mean, v.sum_weight]})
	end

	test "weekly" do
		assert_equal([[0, 0.0, 0.0], [1, 0.0, 0.0], [2, 0.0, 0.0], [3, 0.0, 0.0], [4, 0.0, 0.0], [5, 1440.0, 1.0], [6, 0.0, 0.0]], Pulse.weekly(Node.find_by_title(:fixed60), '2015-05-02').map {|k,v| [k, v.mean, v.sum_weight]})
		assert_equal([[0, 1440.0, 1.0], [1, 1440.0, 1.0], [2, 1440.0, 1.0], [3, 1440.0, 1.0], [4, 1440.0, 1.0], [5, 1440.0, 2.0], [6, 1440.0, 1.5]], Pulse.weekly(Node.find_by_title(:fixed60), '2015-05-9 12:00').map {|k,v| [k, v.mean, v.sum_weight]})
		assert_equal([[0, 1440.0, 1.0], [1, 1440.0, 1.0], [2, 1440.0, 1.0], [3, 1440.0, 1.0], [4, 1440.0, 1.0], [5, 1440.0, 2.0], [6, 1440.0, 1.9993055555555554]], Pulse.weekly(Node.find_by_title(:fixed60), '2015-05-10').map {|k,v| [k, v.mean, v.sum_weight]})
		assert_equal([[0, 1440.0, 1.0], [1, 0.0, 0.0], [2, 0.0, 0.0], [3, 0.0, 0.0], [4, 0.0, 0.0], [5, 1440.0, 1.0], [6, 1440.0, 1.0]], Pulse.weekly(Node.find_by_title(:fixed60), '2015-05-04', 5).map {|k,v| [k, v.mean, v.sum_weight]})
		assert_equal([[0, 1440.0, 1.0], [1, 1440.0, 1.0], [2, 1440.0, 1.0], [3, 1440.0, 1.0], [4, 1440.0, 1.0], [5, 0.0, 0.0], [6, 0.0, 0.0]], Pulse.weekly(Node.find_by_title(:fixed60), '2015-05-08', 5).map {|k,v| [k, v.mean, v.sum_weight]})
		assert_equal([[0, 0.0, 0.0], [1, 0.0, 0.0], [2, 0.0, 0.0], [3, 0.0, 0.0], [4, 0.0, 0.0], [5, 1440.0, 1.0], [6, 0.0, 0.0]], Pulse.weekly(Node.find_by_title(:fixed60), '2015-05-02', 3).map {|k,v| [k, v.mean, v.sum_weight]})
		assert_equal([[0, 1440.0, 1.0], [1, 1440.0, 1.0], [2, 1440.0, 1.0], [3, 0.0, 0.0], [4, 0.0, 0.0], [5, 0.0, 0.0], [6, 0.0, 0.0]], Pulse.weekly(Node.find_by_title(:fixed60), '2015-05-06', 3).map {|k,v| [k, v.mean, v.sum_weight]})
		# assert_equal([[0, 0.24], [1, 0.48], [2, 0.72], [3, 0.96], [4, 1.2], [5, 1.44], [6, 1.68]], Pulse.weekly(Node.find_by_title(:wday)))
		# assert_equal([[0, 0.24], [1, 0.48], [2, 0.72], [3, 0.96], [4, 1.2], [5, 1.44], [6, 1.68]], Pulse.weekly(Node.find_by_title(:wday), '2015-05-08', 7))
	end

	test "monthly" do
		assert_equal([[0, 1440.0, 1.0], [1, 1440.0, 1.0], [2, 1440.0, 1.0], [3, 1440.0, 1.0], [4, 1440.0, 1.0], [5, 1440.0, 1.0], [6, 1440.0, 1.0], [7, 1440.0, 1.0], [8, 1440.0, 0.9993055555555556], [9, 0.0, 0.0], [10, 0.0, 0.0], [11, 0.0, 0.0], [12, 0.0, 0.0], [13, 0.0, 0.0], [14, 0.0, 0.0], [15, 0.0, 0.0], [16, 0.0, 0.0], [17, 0.0, 0.0], [18, 0.0, 0.0], [19, 0.0, 0.0], [20, 0.0, 0.0], [21, 0.0, 0.0], [22, 0.0, 0.0], [23, 0.0, 0.0], [24, 0.0, 0.0], [25, 0.0, 0.0], [26, 0.0, 0.0], [27, 0.0, 0.0], [28, 0.0, 0.0], [29, 0.0, 0.0], [30, 0.0, 0.0]], Pulse.monthly(Node.find_by_title(:fixed60), '2015-05-10').map {|k,v| [k, v.mean, v.sum_weight]})
		assert_equal([[0, 1440.0, 1.0], [1, 1440.0, 1.0], [2, 1440.0, 1.0], [3, 1440.0, 1.0], [4, 1440.0, 1.0], [5, 1440.0, 1.0], [6, 1440.0, 1.0], [7, 1440.0, 1.0], [8, 1440.0, 1.0], [9, 1440.0, 1.0], [10, 1440.0, 1.0], [11, 1440.0, 1.0], [12, 1440.0, 1.0], [13, 1440.0, 1.0], [14, 1440.0, 1.0], [15, 1440.0, 1.0], [16, 1440.0, 1.0], [17, 1440.0, 1.0], [18, 1440.0, 1.0], [19, 1440.0, 1.0], [20, 1440.0, 1.0], [21, 1440.0, 1.0], [22, 1440.0, 1.0], [23, 1440.0, 1.0], [24, 1440.0, 1.0], [25, 1440.0, 1.0], [26, 1440.0, 1.0], [27, 1440.0, 1.0], [28, 1440.0, 1.0], [29, 1440.0, 1.0], [30, 1440.0, 1.0]], Pulse.monthly(Node.find_by_title(:monthly), '2015-06-01', 31).map {|k,v| [k, v.mean, v.sum_weight]})
		assert_equal([[0, 0.0, 0.0], [1, 0.0, 0.0], [2, 0.0, 0.0], [3, 0.0, 0.0], [4, 0.0, 0.0], [5, 0.0, 0.0], [6, 0.0, 0.0], [7, 0.0, 0.0], [8, 0.0, 0.0], [9, 0.0, 0.0], [10, 0.0, 0.0], [11, 0.0, 0.0], [12, 0.0, 0.0], [13, 1680.0, 1.0], [14, 1680.0, 1.0], [15, 1680.0, 1.0], [16, 1680.0, 1.0], [17, 1680.0, 1.0], [18, 1680.0, 1.0], [19, 1680.0, 1.0], [20, 1680.0, 1.0], [21, 1680.0, 1.0], [22, 1680.0, 1.0], [23, 1680.0, 1.0], [24, 1680.0, 1.0], [25, 1680.0, 1.0], [26, 1680.0, 1.0], [27, 1680.0, 1.0], [28, 1680.0, 1.0], [29, 1680.011117802381, 0.9993981481481482], [30, 0.0, 0.0]], Pulse.monthly(Node.find_by_title(:monthly), '2015-07-15', 31).map {|k,v| [k, v.mean, v.sum_weight]})
		assert_equal([[0, 1560.0, 2.0], [1, 1560.0, 2.0], [2, 1560.0, 2.0], [3, 1560.0, 2.0], [4, 1560.0, 2.0], [5, 1560.0, 2.0], [6, 1560.0, 2.0], [7, 1560.0, 2.0], [8, 1560.0, 2.0], [9, 1560.0, 2.0], [10, 1560.0, 2.0], [11, 1560.0, 2.0], [12, 1560.0, 2.0], [13, 1560.0, 2.0], [14, 1560.0, 2.0], [15, 1560.0, 2.0], [16, 1560.0, 2.0], [17, 1560.0, 2.0], [18, 1560.0, 2.0], [19, 1560.0, 2.0], [20, 1560.0, 2.0], [21, 1560.0, 2.0], [22, 1560.0, 2.0], [23, 1560.0, 2.0], [24, 1560.0, 2.0], [25, 1560.0, 2.0], [26, 1560.0, 2.0], [27, 1560.0, 2.0], [28, 1560.0, 2.0], [29, 1559.9694352467177, 1.9993981481481482], [30, 1440.0, 1.0]], Pulse.monthly(Node.find_by_title(:monthly), '2015-07-01').map {|k,v| [k, v.mean, v.sum_weight]})
	end

	test "yearly" do
		assert_equal([[0, 0.0, 0.0], [1, 0.0, 0.0], [2, 0.0, 0.0], [3, 0.0, 0.0], [4, 44640.0, 1.0], [5, 53874.793103448275, 0.9354838709677419], [6, 0.0, 0.0], [7, 0.0, 0.0], [8, 0.0, 0.0], [9, 0.0, 0.0], [10, 0.0, 0.0], [11, 0.0, 0.0]], Pulse.yearly(Node.find_by_title(:monthly), '2015-07-01').map {|k,v| [k, v.mean, v.sum_weight]})
		assert_equal([[0, 0.0, 0.0], [1, 0.0, 0.0], [2, 0.0, 0.0], [3, 0.0, 0.0], [4, 50216.125, 0.25806451612903225], [5, 0.0, 0.0], [6, 0.0, 0.0], [7, 0.0, 0.0], [8, 0.0, 0.0], [9, 0.0, 0.0], [10, 0.0, 0.0], [11, 0.0, 0.0]], Pulse.yearly(Node.find_by_title(:fixed60), '2015-05-10').map {|k,v| [k, v.mean, v.sum_weight]})
		assert_equal([[0, 0.0, 0.0], [1, 0.0, 0.0], [2, 0.0, 0.0], [3, 0.0, 0.0], [4, 44640.0, 1.0], [5, 0.0, 0.0], [6, 0.0, 0.0], [7, 0.0, 0.0], [8, 0.0, 0.0], [9, 0.0, 0.0], [10, 0.0, 0.0], [11, 0.0, 0.0]], Pulse.yearly(Node.find_by_title(:monthly), '2015-06-01', 365).map {|k,v| [k, v.mean, v.sum_weight]})
		assert_equal([[0, 0.0, 0.0], [1, 0.0, 0.0], [2, 0.0, 0.0], [3, 0.0, 0.0], [4, 0.0, 0.0], [5, 53938.892857142855, 0.9032258064516129], [6, 0.0, 0.0], [7, 0.0, 0.0], [8, 0.0, 0.0], [9, 0.0, 0.0], [10, 0.0, 0.0], [11, 0.0, 0.0]], Pulse.yearly(Node.find_by_title(:monthly), '2015-08-01', 60).map {|k,v| [k, v.mean, v.sum_weight]})
	end

	test "daily per month"  do
		assert_equal([[0, 0.0, 0.0], [1, 0.0, 0.0], [2, 0.0, 0.0], [3, 0.0, 0.0], [4, 1440.0, 6.0], [5, 0.0, 0.0], [6, 0.0, 0.0], [7, 0.0, 0.0], [8, 0.0, 0.0], [9, 0.0, 0.0], [10, 0.0, 0.0], [11, 0.0, 0.0]], Pulse.daily_per_month(Node.find_by_title(:fixed60), '2015-05-09', 6).map {|k,v| [k, v.mean, v.sum_weight]})
		assert_equal([[0, 480.0, 9.0], [1, 0.0, 0.0], [2, 0.0, 0.0], [3, 0.0, 0.0], [4, 0.0, 0.0], [5, 0.0, 0.0], [6, 0.0, 0.0], [7, 0.0, 0.0], [8, 0.0, 0.0], [9, 0.0, 0.0], [10, 0.0, 0.0], [11, 480.0, 31.0]], Pulse.daily_per_month(Node.find_by_title(:fixed20), '2015-01-10').map {|k,v| [k, v.mean, v.sum_weight]})
	end

	test "daily_slot_per_month" do
		tz = Time.zone.now.formatted_offset		
		q_f1 = "(extract(hour from timezone('#{tz}', pulse_time)) >= 8 and extract(hour from timezone('#{tz}', pulse_time)) < 19 and extract(dow from timezone('#{tz}', pulse_time)) between 1 and 5 and (extract(month from timezone('#{tz}', pulse_time)), extract(day from timezone('#{tz}', pulse_time))) not in ((1,1),(1,6),(4,25),(5,1),(6,2),(8,15),(11,1),(12,8),(12,25),(12,26)))"
		# q_f1 = "(extract(hour from timezone('#{tz}', pulse_time)) >= 8 and extract(hour from timezone('#{tz}', pulse_time)) < 19)"
		q_f2 = "not (#{q_f1})"
		# assert_equal([[5, 0.66]], Pulse.daily_slot_per_month(Node.find_by_title(:fixed60), q_f1, '2015-05-04', '2015-05-09'))
		q = Pulse.daily_slot_per_month(Node.find_by_title(:fixed60), q_f1, '2015-05-04', '2015-05-09')
		assert_equal([1, 2015, 5], [q.length, q[0].year, q[0].month])
		assert_in_delta(0.66, q[0].power)
		q = Pulse.daily_slot_per_month(Node.find_by_title(:fixed60), q_f2, '2015-05-04', '2015-05-09')
		assert_equal([2015, 5, 0.78], [q[0].year, q[0].month, q[0].power])

		q = Pulse.daily_slot_per_month(Node.find_by_title(:fixed60), q_f1, '2015-05-03', '2015-05-09')
		assert_in_delta(0.55, q[0].power)
		q = Pulse.daily_slot_per_month(Node.find_by_title(:fixed60), q_f2, '2015-05-03', '2015-05-09')
		assert_equal([2015, 5, 0.89], [q[0].year, q[0].month, q[0].power])

		q = Pulse.daily_slot_per_month(Node.find_by_title(:fixed20), q_f1, '2014-12-10', '2015-01-10')
		assert_equal([[2014, 12, 0.14], [2015, 1, 0.12222222222222223]], [[q[0].year, q[0].month, q[0].power], [q[1].year, q[1].month, q[1].power]])
		# assert_in_delta(0.14, q[0].power)
		q = Pulse.daily_slot_per_month(Node.find_by_title(:fixed20), q_f2, '2014-12-10', '2015-01-10')
		assert_equal([[2014, 12, 0.34], [2015, 1, 0.3577777777777778]], [[q[0].year, q[0].month, q[0].power], [q[1].year, q[1].month, q[1].power]])
		# assert_equal([2015, 5, 0.78], [q[0].year, q[0].month, q[0].power])
		# q = Pulse.daily_per_month(Node.find_by_title(:fixed60), '2015-05-03', '2015-05-09')
		# assert_equal([[5, 1.44]], [q[0].year, q[0].month, q[0].power])
	end

	# TODO timezone testing

end
