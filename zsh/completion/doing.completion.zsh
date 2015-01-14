#compdef doing

local ret=1 state

_arguments \
  ':subcommand:->subcommand' \
  '*::options:->options' && ret=0

case $state in
    subcommand)
        local -a subcommands
        subcommands=(
            'help:Shows a list of commands or help for one command'
            'now:Add an entry'
            'note:Add a note to the last entry'
            'meanwhile:Finish any running @meanwhile tasks and optionally create a new one'
            'later:Add an item to the Later section'
            'done:Add a completed item with @done(date). No argument finishes last entry.'
            'finish:Mark last X entries as @done'
            'tag:Tag last entry'
            'mark:Mark last entry as highlighted'
            'show:List all entries'
            'grep:Search for entries'
            'recent:List recent entries'
            'today:List entries from today'
            'yesterday:List entries from yesterday'
            'last:Show the last entry'
            'sections:List sections'
            'choose:Select a section to display from a menu'
            'add_section:Add a new section to the "doing" file'
            'view:Display a user-created view'
            'views:List available custom views'
            'archive:Move entries in between sections'
            'open:Open the "doing" file in an editor'
            'config:Edit the configuration file'
            'undo:Undo the last change to the doing_file'
        )
        _describe -t subcommands 'doing subcommand' subcommands && ret=0
    ;;

    options)
        age=({-a,--age=}"[Age (oldest/newest) (default: newest)]")
        app=({-a,--app=}"[Edit entry with specified app (default: none)")
        archive=({-a,--archive}"[Archive previous @meanwhile entry]")
        back="--back=[Backdate start time (4pm|20m|2h|yesterday noon) (default: none)]"
        boolean=({-b,--boolean=}"[Tag boolean (AND,OR,NONE) (default: OR)]")
        bool=({-b,--bool=}"[Tag boolean (default: AND)]")
        count=({-c,--count=}"[How many recent entries to tag (default: 1)]")
        count=({-c,--count=}"[Max count to show (default: 0)]")
        date=({-d,--date}"[Include date (default: enabled)]")
        editor=( {-e,--editor}"[Edit entry with $EDITOR]")
        finish=({-f,--finish_last}"[Timed entry, marks last entry in section as @done]")
        file=({-f,--file=}"[Specify alternate doing file (default: none)]")
        noarchive="--no-archive[Don't archive previous @meanwhile entry]"
        nodate="--no-date[Don't include date]"
        noeditor="--no-editor[Don't edit entry with $EDITOR]"
        note=({-n,--note=}"[Note (default: none)]")
        notimes="--no-times[Don't show time intervals on @done tasks.]"
        nototals="--no-totals[Don't show intervals with totals at the end of output]"
        output=({-o,--output=}"[Output to export format (csv|html) (default: none)]")
        remove=({-r,--remove}"[Replace/Remove last entry's note]")
        section=({-s,--section=}"[Section (default: Currently)]")
        sort=({-s,--sort=}"[Sort order (asc/desc) (default: asc)]")
        times=({-t,--times}"[Show time intervals on @done tasks (default: enabled)]")
        took=({-t,--took=}"[Set completion date to start date plus XX(mhd) or (HH:MM) (default: none)]")
        totals="--totals[Show intervals with totals at the end of output]"

        case $words[1] in
            now)
                args=( $back $noeditor $editor $note $section $finish )
            ;;

            note)
                args=( $section $editor $remove )
            ;;

            meanwhile)
                args=( $back $noeditor $editor $note $section $archive $noarchive )
            ;;

            later)
                args=( $back $noeditor $editor $note $app )
            ;;

            done)
                args=( $back $took $section {-r,--remove}"[Remove @done tag]" $date $nodate $archive $editor $noeditor )
            ;;

            finish)
                args=( $back $took $section $date $nodate $archive $editor $noeditor )
            ;;

            tag)
                args=( $section $count $date $remove )
            ;;

            mark)
                args=( $section $remove )
            ;;

            show)
                args=( $boolean $count $age $sort $output $times $notimes $totals $nototals )
            ;;

            grep)
                args=( $section $output $times $notimes $totals $nototals )
            ;;

            recent)
                args=( $section $times $notimes $totals $nototals )
            ;;

            today)
                args=( $output $times $notimes $totals $nototals )
            ;;

            yesterday)
                args=( $output $times $notimes $totals $nototals )
            ;;

            view)
                args=( $section $count $output $times $notimes $totals $nototals )
            ;;

            archive)
                args=( $keep $to $bool )
            ;;

            open)
                args=( 
                    "-a [open with app name (default:none)" 
                    "-b [open with app bundle id (default: none)"
                    "-e [open with $EDITOR]"
                )
            ;;

            config)
                args=( $editor )
            ;;

            undo)
                args=( $file )
            ;;

        esac

        _arguments $args && ret=0
    ;;
esac

return ret
