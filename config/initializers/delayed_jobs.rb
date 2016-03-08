
# http://www.sitepoint.com/delayed-jobs-best-practices/

# By default, delayed workers delete failed jobs as soon as they reach the maximum number of attempts. 
# This might be annoying when you want to find the root of a problem and troubleshoot
Delayed::Worker.destroy_failed_jobs = false

# The default max rn time is 4.hours
Delayed::Worker.max_run_time = 15.minutes

