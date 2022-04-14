# Recommended defaults have been setup.
# This file should be changed only when you know what you are doing.

# Flush logs used to create consistent binlogs to be used for incremental backups
every :day, at: '12:00 pm' do
  command "smartmachine runner grids mysql flushlogs"
end

# Create daily backup.
# This also flushes the logs before backup
every :day, at: '12:00 am' do
  command "smartmachine runner grids mysql backup --daily"
end

# Promote currently latest daily backup to weekly backup.
# This is only possible when a daily backup creation has already been completed.
every :monday, at: '3:00 am' do
  command "smartmachine runner grids mysql backup --promote-to-weekly"
end
