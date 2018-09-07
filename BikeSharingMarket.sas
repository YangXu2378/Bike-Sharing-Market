libname project 'D:\440\project'; 
option pageno=1 center nodate linesize=96; 
options fmtsearch=(project); 
ods rtf file='D:\440\project\project.rtf'; 

*title 'Group Project';
proc format library=project; 
  value season_fmt 
    1='Spring' 2='Summer' 3='Fall' 4='Winter'; 
  value year_fmt 
    0=2011 1=2012;
  value month_fmt 
    1='Jan' 2='Feb' 3='Mar' 4='Apr' 5='May' 6='Jun' 7='Jul' 8='Aug' 9='Sep' 10='Oct'
    11='Nov' 12='Dec';
  value holiday_fmt 
    0='Not Holiday' 1='Holiday'; 
  value weekday_fmt 
    0='Sun' 1='Mon' 2='Tues' 3='Wed' 4='Thur' 5='Fri' 6='Sat';
  value workingday_fmt 
    1='Working Day' 0='Weekend or Holiday';
  value weathersit_fmt 
    1='Clear' 2='Mist & Cloudy' 3='Light Precipitation' 4='Heavy Precipitation'; 
run; 

* read in data; 
data project.day; 
  infile 'day.csv' dsd firstobs=2; 
  input instant date:mmddyy. season year month holiday weekday workingday 
        weathersit temp atemp hum windspeed casual registered cnt; 
  format date mmddyy10. season season_fmt. year year_fmt. month month_fmt. holiday holiday_fmt. 
         weekday weekday_fmt. workingday workingday_fmt. weathersit weathersit_fmt. ; 
  label instant='Instant'
        date='Date' 
        season='Season' 
        year='Year' 
        month='Month' 
        holiday='Holiday'
        weekday='Weekday' 
        workingday='Working day' 
        weathersit='Weather Situation' 
        temp='Normalized Temperature in Celsius' 
        atemp='Normalized feeling temperature in Celsius'
        hum='Normalized humidity' 
        windspeed='Normalized wind speed'
		casual='Count of casual users' 
        registered='Count of registered users' 
        cnt='Count of total rental bikes'; 
run; 

data project.hour; 
  infile 'hour.csv' dsd firstobs=2; 
  input instant date:mmddyy. season year month hour holiday weekday workingday 
        weathersit temp atemp hum windspeed casual registered cnt; 
  format date mmddyy10. season season_fmt. year year_fmt. month month_fmt. holiday holiday_fmt. 
         weekday weekday_fmt. workingday workingday_fmt. weathersit weathersit_fmt. ; 
  label instant='Instant'
        date='Date' 
        season='Season' 
        year='Year' 
        month='Month' 
		hour='Hour'
        holiday='Holiday'
        weekday='Weekday' 
        workingday='Working day' 
        weathersit='Weather Situation' 
        temp='Normalized Temperature in Celsius' 
        atemp='Normalized feeling temperature in Celsius'
        hum='Normalized humidity' 
        windspeed='Normalized wind speed'
		casual='Count of casual users' 
        registered='Count of registered users' 
        cnt='Count of total rental bikes';
run; 

proc contents data=project.day; 
  ods select attributes; 
  title 'Attributes of day data set';
run; 

proc contents data=project.hour; 
  ods select attributes; 
  title 'Attributes of hour data set';
run; 

* check missing values; 
proc freq data=project.day nlevels; 
  ods select nlevels; 
  title 'No missing values in day data set'; 
run; 

proc freq data=project.hour nlevels; 
  ods select nlevels;
  title 'No missing values in hour data set'; 
run; 

* check holidays; 
title1 'Data checking by Holiday';
proc print data=project.day label;
  where holiday=1;
  var date holiday;  
run; 

* descriptive statistics; 
proc means data=project.day; 
  var temp atemp hum windspeed casual registered cnt; 
  title 'Descriptive statistics of day data set';
run; 

proc means data=project.hour; 
  var temp atemp hum windspeed casual registered cnt;
  title 'Descriptive statistics of hour data set';
run; 

* check specific demand; 
proc sort data=project.day
          out=cntsort; 
  by descending cnt; 
run; 

proc print data=cntsort (obs=10); 
  var date cnt; 
  title 'No specific demand for bike sharing';
run; 

* transfer hourly to daily; 
proc sort data=project.hour; 
  by dteday; 
run; 

proc sort data=project.day; 
  by dteday; 
run; 

data hour_day; 
  set project.hour; 
  by dteday; 
  if first.dteday then do; 
     num_hours=0; 
     sum_cnt=0; 
  end; 
     num_hours+1; 
     sum_cnt+cnt; 
  if last.dteday;
  keep dteday num_hours sum_cnt; 
run; 

* compare 'hour' and 'day';
data compare_sum; 
  merge project.day hour_day; 
  by dteday; 
  keep dteday sum_cnt cnt; 
run; 

proc print data=compare_sum;
  title 'Check difference in total counts between hour.csv and day.csv';
  where sum_cnt~=cnt; 
run; *no mistake in calculating cnt; 

* compare total counts by seasons for 2 years;
proc sort data=project.day; 
  by year season; 
run; 

data season_2011 (keep=year season tot_cnt)
     season_2012 (keep=year season tot_cnt); 
  set project.day (keep=year season cnt); 
  by year season; 
  if first.season then tot_cnt=0; 
  tot_cnt+cnt; 
  if last.season; 
  select (year); 
    when (0) output season_2011; 
    otherwise output season_2012; 
  end; 
  label tot_cnt='Total count of rental bikes';
run; 

data season (drop=year); 
  merge season_2011 season_2012(rename=(tot_cnt=tot_cnt2012));  
  by season;
  increase=tot_cnt2012-tot_cnt; 
  inc_rate=increase/tot_cnt; 
  label tot_cnt='Total counts of rental bikes in 2011'
        tot_cnt2012='Total counts of rental bikes in 2012'
		increase='Increase'
		inc_rate='Increase rate';
  format inc_rate percent10.; 
run; 

proc print data=season label; 
	title1 'Compare total counts by season for 2 years';
run;


*compare customer;
proc sort data=project.day;
	by Year ;
run;
data compare_customer (keep=year tot_casual tot_register total casual_pct register_pct);
	set project.day (keep=year casual registered cnt);
	by Year ;
	if first.Year then do; 
    	tot_casual=0; 
    	tot_register=0; 
    	total=0; 
	end; 
	tot_casual+casual;
	tot_register+registered;
	total+cnt;
	if last.Year;
	casual_pct=tot_casual/total;
	register_pct=tot_register/total;
	format casual_pct register_pct percent6.2;
	label tot_casual='Total rentals of casual users' tot_register='Total rentals of registered users' total='Total rental'
		  casual_pct='Percentage of rental of casual users' register_pct='Percentage of rental of register_users';
run;

proc print data=compare_customer label noobs; 
	title 'Compare total counts for casual users and registered users';
run; 
/* */

*compare working day vs holiday or weekend;
data working_vs_nonworking(keep=nonwork_count work_count total nonwork_pct work_pct);
	set project.day (keep=workingday cnt);
	if workingday=1 then work_count+cnt;
	else nonwork_count+cnt;
	total+cnt;
	nonwork_pct=nonwork_count/total;
	work_pct=work_count/total;
	format nonwork_pct work_pct percent6.2;
	label nonwork_count='Total counts on holiday or weekend' work_count='Total counts on working days' total='Counts in total'
		  nonwork_pct='Percentage of rental counts on holiday or weekend' work_pct='Percentage of rental counts on working days';
run;

proc print data=working_vs_nonworking (firstobs=731) noobs label;
	title 'Compare rental counts on working days and non-working days';
run;

/*conditional output for 2011 and 2012*/
proc sort data=project.day;
     by year weathersit;
run; 

data project.weather_2011 project.weather_2012;
     set project.day;
	 by year weathersit;
	 if first.weathersit then total_weather=0;
	 total_weather+cnt;
	 if last.weathersit;
	 label total_weather='total count under different weather';
	 select (year); 
       when (0) output project.weather_2011;
	   otherwise output project.weather_2012;
	 end; 
run; 

/*merge 2011 2012*/
data project.weather_merge(keep=weathersit total_weather_2011 total_weather diff increase_rate);
     merge project.weather_2011(rename=(total_weather=total_weather_2011)) project.weather_2012;
	 by weathersit;
	 label total_weather_2011='Total count of rental bikes under different weather situation in 2011' 
	       total_weather='Total count of rental bikes under different weather situation in 2012';
	 diff=total_weather - total_weather_2011;
	 increase_rate=diff/total_weather_2011;
	 format increase_rate percent10.;
run;

proc print data=project.weather_merge label;
	title1 'Analysis of total count of rental bikes under different weather situation from 2011 to 2012';
run;

*compare 3 parts of the day;
proc sort data = project.hour;
  by year hour;
run;

data hour;
  set project.hour;
  by year hour; 
  select; 
    when (0 <= hour < 8) time='Morning'; 
    when (8 <= hour < 16) time='Noon';
    otherwise time='Night'; 
  end; 
run; 

proc sort data=hour; 
  by year time; 
run; 

data time_period (keep=year time tot_cnt); 
  set hour; 
  by year time; 
  if first.time then tot_cnt=0; 
  tot_cnt+cnt;
  if last.time; 
  label year='Year'
        time='Time period'
        tot_cnt='Total count of rental bikes';
run; 

/*proc print data =time_period label;
run;*/

proc sort data=time_period; 
  by year time; 
run; 

data time_2011
     time_2012; 
  set time_period; 
  by year time; 
  select (year); 
    when (0) output time_2011; 
	otherwise output time_2012; 
  end;
  label tot_cnt='Total count of rental bikes';
run; 

data time (drop=year); 
  merge time_2011 time_2012(rename=(tot_cnt=tot_cnt2012));  
  by time;
  increase=tot_cnt2012-tot_cnt; 
  inc_rate=increase/tot_cnt; 
  label tot_cnt='Total counts of rental bikes in 2011'
        tot_cnt2012='Total counts of rental bikes in 2012'
		increase='Increase'
		inc_rate='Increase rate';
  format inc_rate percent10.; 
run; 

proc print data = time label;
	title 'Analysis of total count of rental bikes under different time of the day from 2011 to 2012';
run;



ods rtf close;


