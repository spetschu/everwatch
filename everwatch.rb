#!/usr/bin/env ruby
# everwatch.rb by Brett Terpstra, 2011
# http://brettterpstra.com/2011/11/14/marked-scripts-nvalt-evernote-marsedit-scrivener/
# http://support.markedapp.com/kb/how-to-tips-and-tricks/marked-bonus-pack-scripts-commands-and-bundles
# Updated for latest Evernote configuration (2013) and quick launch of Marked.app - spetschu
#
# Watch Evernote for updates and put the current content of the editor into a preview file for Marked.app
# <http://markedapp.com>

`open /Applications/Marked.app --args ~/EvernoteSelection.md`

trap("SIGINT") { exit }

#watch_folder = File.expand_path("~/Library/Application Support/Evernote/data")
account = "youraccount"
watch_folder = File.expand_path("~/Library/Containers/com.evernote.Evernote/Data/Library/Application Support/Evernote/accounts/Evernote/#{account}/content")
marked_note = File.expand_path("~/EvernoteSelection.md")
counter = 0

while true do # repeat infinitely
  
  # recursive glob needed for current Evernote setup
  files = Dir.glob( File.join( watch_folder, "**/*") )

  # check for timestamp changes since the last loop
  new_hash = files.collect {|f| [ f, File.stat(f).mtime.to_i ] }
  hash ||= new_hash
  diff_hash = new_hash - hash

  if diff_hash.empty? # if there's no change
    # if it's been less than 10 seconds, increment the counter
    # otherwise, set it to zero and wait for new changes
    counter = (counter < 10 && counter > 0) ? counter + 1 : 0
  else
    hash = new_hash
    counter = 1
  end

  if counter > 0 # if the time is running

    note = %x{ osascript <<APPLESCRIPT
        tell application "Evernote"
            if selection is not {} then
                set the_selection to selection
                return HTML content of item 1 of the_selection
            else
                return ""
            end if
        end tell
APPLESCRIPT}

    unless note == '' # if we got something back from the AppleScript
      txtnote = %x{echo '#{note}'|textutil -stdin -convert txt -stdout}
      watch_note = File.new("#{marked_note}",'w')
      watch_note.puts txtnote
      watch_note.close
    end

    # sleep an extra second on changes because Marked only
    # reads changes every 2 seconds
    sleep 1 

  end
    
  sleep 1

end
