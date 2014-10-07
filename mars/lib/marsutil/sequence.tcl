#-----------------------------------------------------------------------
# TITLE:
#    sequence.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    sequence(n): Sequence diagram library, for drawing sequence(5)
#    diagrams.
#
#    WARNING: Loads Pixane automatically the first time a diagram is
#    rendered!
#
# PHASES:
#    The diagram is produced in three phases:
#
#    Parsing:   The sequence(5) input is parsed
#    Layout:    The elements are layed out and their positions determined
#    Rendering: The elements are rendered into a Pixane image
#
# LAYOUT
#    The diagram is layed out according to certain parameters and the
#    sizes of the elements being drawn.  The basic parameters are stored
#    in the parms() array.  Current metrics for the diagram as a whole
#    are in the page() array.  Data about the diagram elements are in
#    the data() array.  
#
#-----------------------------------------------------------------------

namespace eval ::marsutil:: {
    namespace export sequence
}

#-----------------------------------------------------------------------
# sequence ensemble

snit::type ::marsutil::sequence {
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Parameters
    #
    #    parms(margin): 
    #        The margin between the edge of the diagram and the
    #        data content on all four sides.
    #
    #    parms(xstep):
    #        The separation between actor boxes in the diagram
    #
    #        +-----------+         +-----------+
    #        |   actor   |<-xstep->|   actor   |
    #        +-----------+         +-----------+
    #
    #    parms(ystep):
    #        The separation between successive rows in the diagram.  
    #        Each row is a single element.
    #
    #        |       message 1       |
    #        |---------------------->|
    #        |          ^            |
    #        |          |            |
    #        |        ystep          |
    #        |          |            |
    #        |          v            |
    #        |       message 2       |
    #        |<----------------------|
    #        |                       |
    #
    #    parms(padding):
    #        The separation between the text in a box and the border 
    #        of the box.
    #
    #    parms(opaquepadding):
    #        For text with an opaque background, the padding around
    #        the text.
    #
    #    parms(mincolwidth):
    #        The minimum width of an actor's column, i.e., the minimum 
    #        width of the box containing the actor's name.
    #
    #    parms(font):
    #        Name of the default font
    #
    #    parms(fontsize):
    #        Size of the default font
    #
    #    parms(titlesize):
    #        Size of the title font
    #
    #    parms(linespacing):
    #        Pixels between lines of wrapped text.
    #
    #    parms(fg), parms(bg):
    #        The foreground and background colors
    #
    #    parms(arrow):
    #        The x/y extent of each blade of the arrowhead on message arrows.
    #
    #    parms(dotradius):
    #        The radius of a dot drawn at the tail of each message arrow.

    typevariable parms -array {
        margin        5
        xstep         10
        ystep         15
        padding       7
        opaquepadding 3
        mincolwidth   90
        font          sansserif
        fontsize      12
        titlesize     16
        linespacing   4
        fg            black
        bg            white
        arrow         6
        dotradius     2
    }

    #-------------------------------------------------------------------
    # Page Metrics
    #
    #  page(x), page(y):
    #      Used during layout to keep track of current position.
    #
    #  page(xmin), page(ymin), page(xmax), page(ymax):
    #      Minimum and maximum x and y values for data pixels.
    #
    #  page(colleft), page(colright):
    #      colleft is the x coordinate of the left edge of the leftmost
    #      column; colright is the x coordinate of the right edge of
    #      the rightmost column.
    #
    #  page(width), page(height):
    #      Dimensions of the finished diagram.
    #
    #  page(hfont):
    #      Pixane font handle for default font
    #
    #  page(textheight):
    #      Height of one line of text given default font.
    #
    #  page(textasc)
    #      Distance from top of line to baseline given default font.
    #
    #  page(titleheight):
    #      Height of one line of text given title font.
    #
    #  page(xindex):
    #      X-coordinate of right-hand bound of index column.
    #
    #  Note that:
    #      page(xmin)   = parms(margin)
    #      page(ymin)   = parms(margin)
    #      page(width)  = page(xmax) + parms(margin)
    #      page(height) = page(ymax) + parms(margin)

    typevariable page -array { }

    #-------------------------------------------------------------------
    # Element Data
    #
    #  The diagram consists of an optional title, 1 to N actors, and 
    #  0 or more body elements, which are numbered m=1 to M.  The 
    #  following entries describe the data stored for each element.  
    #  The characters (P) and (L) indicate that the data is produced 
    #  by the Parsing or Layout steps, respectively.
    #
    #  data(title):   Dictionary of title data:
    #
    #      text:      (P) The title text string: one line of text
    #      x,y:       (L) Text is drawn at x,y (center,top).  x is the 
    #                     x coordinate of the center line of the 
    #                     diagram.
    #
    #  data(actors):  (P) List of actor names
    #
    #  data(x-$name): (L) x coordinate of center of column for
    #                 the named actor.  This is a separate entry 
    #                 because it is frequently used.
    #
    #  data(actor-$name): Dictionary of actor data
    #      name:      (P) The actor's name
    #      box:       (L) (x1,y1,x2,y2) of the actor's box
    #      y:         (L) Text is drawn at x,y (center,baseline), where
    #                 x is data(x-$name).
    #
    #  data(count):   (P) Count of body elements
    #  data(icount):  (P) Count of indexed body elements
    #
    #  data(body-$i): (P,L) Dictionary of element data for body 
    #                 element i.  The fields depend on the element.
    #                   
    #  message:
    #     etype:      (P) "message"
    #     index:      (P) Displayed index number
    #     from:       (P) The from actor
    #     to:         (P) The list of to actors
    #     text:       (P) The message text
    #     align:      (L) left, right, center
    #     x,ytext     (L) Text is drawn at x,ytext ($align,baseline)
    #     yarrow      (L) y-coordinate for errors.
    #     
    #  comment:
    #     etype:      (P) "comment"
    #     text:       (P) The comment text, (L) the wrapped text
    #     box:        (L) (x1,y1,x2,y2) of the comment box
    #     x, y:       (L) Text is drawn at x,y (left, top).
    #
    #  action:
    #     etype       (P) "action"
    #     index:      (P) Displayed index number
    #     actor:      (P) Actor doing the action
    #     text:       (P) The action text, (L) the wrapped text
    #     box:        (L) (x1,y1,x2,y2) of the action box
    #     x, y:       (L) Text is drawn at x,y (left, top).

    typevariable data -array { }

    # narration: array of element narrative text, by index.  The 
    # overall narrative is saved under key "diagram".

    typevariable narration -array {}

    #-------------------------------------------------------------------
    # Public Methods

    # render sequence
    #
    # sequence      sequence(5) input text
    #
    # Processes the input and returns a pixane image containing the
    # rendered diagram.

    typemethod render {sequence} {
        # FIRST, load Pixane if it isn't already loaded.
        package require pixane

        # NEXT, parse the input
        ParseInput $sequence

        # NEXT, layout the elements
        LayoutElements

        # NEXT, render them into a pixane image
        set diagram [RenderDiagram]

        # NEXT, return the diagram
        return $diagram
    }

    # renderas filename sequence
    #
    # filename      The name of the output file; it should end with .gif
    # sequence      sequence(5) input text
    #
    # Processes the input and outputs an image file containing the
    # rendered diagram.

    typemethod renderas {filename sequence} {
        set diagram [$type render $sequence]

        try {
            pixane save $diagram -file $filename -format GIF
        } finally {
            pixane delete $diagram
        }

        return
    }


    # narration
    #
    # Returns the narrative text for the last diagram rendered as
    # a dictionary whose keys are "diagram" for the overall narrative,
    # and the index number for the message and action narrative.
    #
    # Note that if no narrative was included in the input, the
    # result will be the empty list.
    
    typemethod narration {} {
        array get narration
    }

    #-------------------------------------------------------------------
    # Phase: Parsing

    # ParseInput text
    #
    # text        seq(5) input
    #
    # Parses the input.

    proc ParseInput {text} {
        # FIRST, initialize the data
        array unset data

        set data(actors)      [list]
        set data(count)       0
        set data(icount)      0

        array unset narration

        # NEXT, create the safe interpreter
        set interp [interp create -safe]

        $interp alias title     [myproc title]
        $interp alias narrative [myproc narrative]
        $interp alias actor     [myproc actor]
        $interp alias message   [myproc message]
        $interp alias comment   [myproc comment]
        $interp alias action    [myproc action]

        # NEXT, parse the text
        try {
            $interp eval $text
        } finally {
            interp delete $interp
        }
    }

    #-------------------------------------------------------------------
    # seq(5) commands

    # title title
    #
    # title    A title string
    #
    # Defines the diagram's title

    proc title {title} {
        # FIRST, check errors
        require {![info exists data(title)]} "title already defined"

        # NEXT, save the parsed data
        set data(title) [dict create text [StripLine $title]]
    }

    # narrative text
    #
    # text         Narrative text, unformatted
    #
    # Narrative text for the diagram as a whole.
    
    proc narrative {text} {
        set narration(diagram) [StripLine $text]
    }

    # actor name
    #
    # name     An actor name
    #
    # Defines an actor in the diagram, i.e., a column.

    proc actor {name} {
        # FIRST, check errors
        set name [StripLine $name]
        require {$name ni $data(actors)} "duplicate actor: \"$name\""

        # NEXT, save the actor
        lappend data(actors) $name
        set data(actor-$name) [dict create name $name]
    }

    # message from to text ?narrative?
    #
    # from       The actor sending the message
    # to         A list of the actors to which the message is sent.
    # text       The name of the message (stripped)
    # narrative  Optional narrative text
    #
    # Define a message from one actor to one or more others.
    # An arrow is drawn from the "from" actor to each of the "to" actors.
    # The text is drawn centered above the arrows.

    proc message {from to text {narrative ""}} {
        # FIRST, check errors
        require {$from in $data(actors)} "Unknown actor: \"$from\""

        foreach name $to {
            require {$name in $data(actors)} "Unknown actor: \"$name\""
        }

        # NEXT, increment element count
        set i     [incr data(count)]
        set index [incr data(icount)]

        # NEXT, save the data
        set data(body-$i) [dict create \
                               etype  message \
                               index  $index  \
                               from   $from   \
                               to     $to     \
                               text   $text   \
                               align  {}      \
                               x      {}      \
                               ytext  {}      \
                               yarrow {}      ]

        # NEXT, save the narrative
        set narrative [StripLine $narrative]

        if {$narrative ne ""} {
            set narration($index) $narrative
        }
    }

    # comment text
    #
    # Adds a text comment across the diagram

    proc comment {text} {
        set i [incr data(count)]

        set data(body-$i) \
            [dict create                 \
                 etype comment           \
                 text  [StripLine $text] \
                 box   {}                \
                 x     {}                \
                 y     {}                ]
    }
    
    # action actor text ?narrative?
    #
    # actor      The actor performing the action
    # text       The text of the action
    # narrative  Optional narrative text
    #
    # Define an action taken by one actor.

    proc action {actor text {narrative ""}} {
        # FIRST, check errors
        require {$actor in $data(actors)} "Unknown actor: \"$actor\""

        # NEXT, increment element count
        set i     [incr data(count)]
        set index [incr data(icount)]

        # NEXT, save the data
        set data(body-$i) [dict create \
                               etype  action  \
                               index  $index  \
                               actor  $actor  \
                               text   $text   \
                               box    {}      \
                               x      {}      \
                               y      {}      ]

        # NEXT, save the narrative
        set narrative [StripLine $narrative]

        if {$narrative ne ""} {
            set narration($index) $narrative
        }
    }

    #-------------------------------------------------------------------
    # Phase: Layout

    # LayoutElements
    #
    # Renders the parsed input

    proc LayoutElements {} {
        # FIRST, Initialize the computation
        InitializePageMetrics

        # NEXT, Compute the column coordinates for the body element 
        # index numbers
        LayoutIndexWidth

        # NEXT, set the left bound for the actor columns
        let page(colleft) {$page(xindex) + $parms(xstep)}

        # NEXT, Compute the x coordinates for the actor columns
        foreach name $data(actors) {
            LayoutActorWidth $name
        }

        # NEXT, determine the maximum extent of the diagram's data.
        # Note that we've gone an xstep too far.
        #
        # xmax might be increased during subsequent
        # layout.
        let page(colright) {$page(x) - $parms(xstep)}
        set page(xmax)     $page(colright)

        unset page(x)

        # NOTE: At this point, we know the width allocations.  It's
        # time to start laying out elements from top to bottom.

        # NEXT, The title, if any.
        if {[info exists data(title)]} {
            LayoutTitle
        }

        # NEXT, at this point finish laying out the actors
        LayoutActors

        # NEXT, layout the body elements
        for {set i 1} {$i <= $data(count)} {incr i} {
            Layout_[dict get $data(body-$i) etype] $i
        }

        # NEXT, determine the total width and height of the diagram.
        let page(width) {$page(xmax) + $parms(margin)}

        let page(ymax)   $page(y)
        let page(height) {$page(ymax) + $parms(margin)}
        unset page(y)

    }

    # InitializePageMetrics
    #
    # Set up the initial page metrics.

    proc InitializePageMetrics {} {
        # xmin, ymin
        set page(xmin)  $parms(margin)
        set page(ymin)  $parms(margin)

        # hfont
        set page(hfont) [pixfont create -builtin $parms(font)]

        # textheight
        let page(textheight) [TextHeight $parms(fontsize)]

        # textasc
        let page(textasc)   [TextAscent $parms(fontsize)]
        
        # titleheight
        let page(titleheight) [TextHeight $parms(titlesize)]

        # x, y
        set page(x) $page(xmin)
        set page(y) $page(ymin)
    }

    # LayoutIndexWidth
    #
    # The index column is a slim column at the left of the diagram that
    # contains the index number for each body element.  This procedure
    # sets page(xindex) to the right-hand boundary of the column, and
    # updates page(x) to the left-hand boundary of the next column.

    proc LayoutIndexWidth {} {
        # FIRST, step through the index values, and find the widest.
        set maxwid 0

        for {set i 1} {$i <= $data(count)} {incr i} {
            let maxwid {max([TextWid $i],$maxwid)}
        }
        
        # NEXT, set xindex
        let page(xindex) {$page(x) + $maxwid}

        # NEXT, set up for the next column
        let page(x) {$page(xindex) + $parms(xstep)}
    }

    # LayoutActorWidth name
    #
    # name     The name of an actor
    #
    # Computes the x coordinates for the actor's column.

    proc LayoutActorWidth {name} {
        # FIRST, determine the width required to display the
        # name: the name width plus twice the padding.

        let wid {[TextWid $name] + 2*$parms(padding)}

        # NEXT, there's a minimum column width.
        let wid {max($wid, $parms(mincolwidth))}

        # NEXT, compute the x coordinates of the actor's data
        let x {$page(x) + $wid/2}
        set x1 $page(x)
        let x2 {$page(x) + $wid}

        # NEXT, save them.
        set data(x-$name) $x
        dict set data(actor-$name) y   {}
        dict set data(actor-$name) box [list $x1 {} $x2 {}]

        # NEXT, set up for the next column
        let page(x) {$x2 + $parms(xstep)}
    }

    # LayoutTitle
    #
    # Lays out the title, centered at the top of the diagram, and
    # leaves space for the next element.

    proc LayoutTitle {} {
        # FIRST, compute the x and y values
        let x {($page(xmin) + $page(xmax)) / 2}
        set y $page(y)

        # NEXT, save the result
        dict set data(title) x $x
        dict set data(title) y $y

        # NEXT, leave space for the next element.
        let page(y) {$y + $page(titleheight) + $parms(ystep)}
    }

    # LayoutActors
    #
    # Computes the y coordinates for the row of actor names

    proc LayoutActors {} {
        # FIRST, compute the y1 and y2 of the actor box
        set y1 $page(y)
        let y2 {$y1 + $page(textasc) + 2*$parms(padding)}

        # NEXT, compute the y of the actor text
        let ytext {$page(y) + $parms(padding) + $page(textasc)}
            
        # NEXT, save this for each actor
        foreach name $data(actors) {
            dict with data(actor-$name) {
                set y $ytext
                lset box 1 $y1
                lset box 3 $y2
            }
        }

        # NEXT, leave space
        let page(y) {$y2 + $parms(ystep)}
    }

    # Layout_message i
    #
    # i     index of the message element
    #
    # Lays out the message.

    proc Layout_message {i} {
        dict with data(body-$i) {
            # Determine the min and max bounds of the message arrows.
            set xmin $data(x-$from)
            set xmax $data(x-$from)

            foreach name $to {
                let xmin {min($data(x-$name),$xmin)}
                let xmax {max($data(x-$name),$xmax)}
            }
            
            set x $data(x-$from)

            # Determine the x coordinate and alignment of message
            # text.  Slide the text to right or left as need be to
            # stay within bounds.

            set wid [TextWid $text]

            if {$xmin == $data(x-$from)} {
                incr x $parms(padding)
                set align left

                set x1 $x
                let x2 {$x + $wid}
            } elseif {$xmax == $data(x-$from)} {
                incr x -$parms(padding)
                set align right

                set x2 $x
                let x1 {$x2 - $wid}

            } else {
                set align center

                let x1 {$x - $wid/2}
                let x2 {$x + $wid/2}
            }

            # Are we over at the left?  If so, shift it over.
            let delta {$page(colleft) - $x1}

            if {$delta > 0} {
                incr x $delta
                incr x2 $delta
            }

            # NEXT, are we over at the right?  If so, extend the page
            if {$x2 > $page(xmax)} {
                set page(xmax) $x2
            }

            # y-coordinate of baseline of message text
            let ytext {$page(y) + $page(textasc) + $parms(padding)}

            # y-coordinate of arrow(s)
            let yarrow {
                $page(y) + $page(textheight) + $parms(padding) + $parms(arrow)
            }

            # Leave space
            let page(y) {$yarrow + $parms(ystep)}
        }
    }

    # Layout_comment i
    #
    # i     index of the comment element
    #
    # Lays out the comment.

    proc Layout_comment {i} {
        dict with data(body-$i) {
            # FIRST, determine the maximum text width: the diagram
            # data width less twice the padding.
            let maxwid {$page(colright) - $page(colleft) - 2*$parms(padding)}

            # NEXT, wrap the text to that width.  The result is
            # a list of lines.
            set text [WrapText $maxwid $text]

            # NEXT, determine the height of the text:
            set n [llength $text]

            let height {($n-1)*($page(textheight) + $parms(linespacing)) + $page(textasc)}
            
            # NEXT, save the box
            set x1 $page(colleft)
            set y1 $page(y)
            set x2 $page(colright)
            let y2 {$y1 + $height + 2*$parms(padding)}

            set box [list $x1 $y1 $x2 $y2]

            # NEXT, save x and y
            let x {$page(colleft) + $parms(padding)}
            let y {$page(y)       + $parms(padding)}

            # NEXT, leave space
            let page(y) {$y2 + $parms(ystep)}
        }
    }
  
    # Layout_action i
    #
    # i     index of the action element
    #
    # Lays out the action.

    proc Layout_action {i} {
        dict with data(body-$i) {
            # FIRST, determine the maximum text width.  It can't
            # go past xmin/xmax, and can't get closer than xstep to 
            # an actor's vertical line.

            set ndx [lsearch -exact $data(actors) $actor]
            set before [lindex $data(actors) $ndx-1]
            set after  [lindex $data(actors) $ndx+1]

            if {$before eq ""} {
                let x1 {$page(colleft)}
            } else {
                let x1 {$data(x-$before) + $parms(xstep)}
            }

            if {$after eq ""} {
                set x2 $page(colright)
            } else {
                let x2 {$data(x-$after) - $parms(xstep)}
            }
            
            
            let maxwid {$x2 - $x1 - 2*$parms(padding)}

            # NEXT, wrap the text to that width.  The result is
            # a list of lines.
            set text [WrapText $maxwid $text]

            # NEXT, determine the height of the text:
            set n [llength $text]

            let height {($n-1)*($page(textheight) + $parms(linespacing)) + $page(textasc)}
            
            # NEXT, save the box
            set y1 $page(y)
            let y2 {$y1 + $height + 2*$parms(padding)}

            set box [list $x1 $y1 $x2 $y2]

            # NEXT, save x and y
            let x {$x1      + $parms(padding)}
            let y {$page(y) + $parms(padding)}

            # NEXT, leave space
            let page(y) {$y2 + $parms(ystep)}
        }
    }

    # TextWid text
    #
    # text      A line of text
    #
    # Returns the width of the line of text, using the default font.

    proc TextWid {text} {
        lassign [pixfont measure $page(hfont) $parms(fontsize) $text] \
                wid asc desc

        return $wid
    }

    # TextHeight size
    #
    # size      A font size
    #
    # Returns the height of a line of text given the default font and
    # the font size.

    proc TextHeight {size} {
        lassign [pixfont measure $page(hfont) $size "Mg"] \
                wid asc desc

        return [expr {$asc + $desc}]
    }

    # TextAscent size
    #
    # size      A font size
    #
    # Returns the distance from the top of a line of text to its
    # baseline.

    proc TextAscent {size} {
        lassign [pixfont measure $page(hfont) $size "Mg"] \
                wid asc desc

        return $asc
    }

    #-------------------------------------------------------------------
    # Phase: Rendering

    # RenderDiagram
    #
    # Renders the parsed input

    proc RenderDiagram {} {
        # FIRST, create the image.
        set pix [pixane create]

        pixane resize  $pix $page(width) $page(height)
        pixane color   $pix $parms(bg)
        pixane fill    $pix
        pixane color   $pix $parms(fg)
        pixane bgcolor $pix $parms(bg)

        # NEXT, render the title, if any
        if {[info exists data(title)]} {
            dict with data(title) {
                pixane text $pix $x $y        \
                    -text   $text             \
                    -font   $page(hfont)      \
                    -size   $parms(titlesize) \
                    -align  center            \
                    -valign top
            }
        }

        # NEXT, render the actors
        foreach name $data(actors) {
            dict with data(actor-$name) {
                DrawBox $pix {*}$box

                pixane text $pix $data(x-$name) $y \
                    -text   $name                  \
                    -font   $page(hfont)           \
                    -size   $parms(fontsize)       \
                    -align  center                 \
                    -valign baseline
                
                set y2 [lindex $box 3]

                pixane line $pix $data(x-$name) $y2 $data(x-$name) $page(ymax)
            }
        }

        # NEXT, render the body elements
        for {set i 1} {$i <= $data(count)} {incr i} {
            Render_[dict get $data(body-$i) etype] $pix $i
        }

        # NEXT, return the diagram
        return $pix
    }

    # Render_message pix i
    #
    # pix    The Pixane image
    # i      The element index

    proc Render_message {pix i} {
        dict with data(body-$i) {
            # Render the index
            pixane text $pix $page(xindex) $yarrow \
                -text    $index                    \
                -font    $page(hfont)              \
                -size    $parms(fontsize)          \
                -align   right                     \
                -valign  baseline

            # Render the text
            DrawOpaqueText $pix $x $ytext $align $text
            
            # Render the arrows
            set xfrom $data(x-$from)

            pixane rectangle $pix \
                [expr {$xfrom  - $parms(dotradius)}] \
                [expr {$yarrow - $parms(dotradius)}] \
                [expr {1 + 2*$parms(dotradius)}]         \
                [expr {1 + 2*$parms(dotradius)}]

            foreach name $to {
                set xto $data(x-$name)
                
                pixane line $pix $xfrom $yarrow $xto $yarrow
                
                if {$xto > $xfrom} {
                    let xa {$xto - $parms(arrow)}
                } else {
                    let xa {$xto + $parms(arrow)}
                }

                pixane line $pix \
                    $xto $yarrow $xa [expr {$yarrow - $parms(arrow)}]
                pixane line $pix \
                    $xto $yarrow $xa [expr {$yarrow + $parms(arrow)}]
            }
        }
    }

    # Render_comment pix i
    #
    # pix    The Pixane image
    # i      The element index

    proc Render_comment {pix i} {
        dict with data(body-$i) {
            # Draw the box
            DrawBox $pix {*}$box

            # Write each line of text
            DrawTextBlock $pix $x $y $text
        }
    }

    # Render_action pix i
    #
    # pix    The Pixane image
    # i      The element index

    proc Render_action {pix i} {
        dict with data(body-$i) {
            # Render the index
            pixane text $pix $page(xindex) $y \
                -text    $index               \
                -font    $page(hfont)         \
                -size    $parms(fontsize)     \
                -align   right                \
                -valign  top

            # Draw the box
            DrawBox $pix {*}$box

            # Write each line of text
            DrawTextBlock $pix $x $y $text
        }
    }


    # DrawBox pix x1 y1 x2 y2
    #
    # Draws a box with a white fill

    proc DrawBox {pix x1 y1 x2 y2} {
        let wid {$x2 - $x1}
        let ht  {$y2 - $y1}

        pixane color     $pix $parms(bg)
        pixane rectangle $pix $x1 $y1 $wid $ht

        pixane color $pix $parms(fg)
        pixane line  $pix $x1 $y1   $x1 $y2   $x2 $y2   $x2 $y1   $x1 $y1
    }

    # DrawBackground pix x1 y1 x2 y2
    #
    # Draws a rectangle in the background color

    proc DrawBackground {pix x1 y1 x2 y2} {
        let wid {$x2 - $x1}
        let ht  {$y2 - $y1}

        pixane color     $pix $parms(bg)
        pixane rectangle $pix $x1 $y1 $wid $ht
        pixane color $pix $parms(fg)
    }

    # DrawTextBlock pix x y lines
    #
    # pix   The pix image
    # x,y   Upper left corner of the block
    # lines List of lines of text.
    #
    # Draws the text block going down from y.

    proc DrawTextBlock {pix x y lines} {
        set yline $y

        foreach line $lines {
            # Get the baseline
            let ybase {$yline + $page(textasc)}

            # Render the text
            pixane text $pix $x $ybase     \
                -text    $line             \
                -font    $page(hfont)      \
                -size    $parms(fontsize)  \
                -align   left              \
                -valign  baseline
            
            let yline {$yline + $page(textheight) + $parms(linespacing)}
        }
    }

    # DrawOpaqueText pix x y align padding text
    #
    # pix      Pixane image
    # x,y      x,y at which the text will be drawn
    # align    left,right,center
    # text     text string (one line)
    #
    # Determines the region covered by the text, and fills it with
    # the background color before drawing the text. Leaves $padding
    # pixels blank above the top and below the baseline.

    proc DrawOpaqueText {pix x y align text} {
        # FIRST, measure the text
        lassign [pixfont measure $page(hfont) $parms(fontsize) $text] \
            twid asc desc

        # NEXT, determine the x extent
        let wid {$twid + 2*$parms(opaquepadding)}

        switch -exact -- $align {
            left   { let x1 {$x - $parms(opaquepadding)}           }
            right  { let x1 {$x - $twid - $parms(opaquepadding)}   }
            center { let x1 {$x - $parms(opaquepadding) - $twid/2} }
        }

        # NEXT, determine the y extent.  Remember that the "y" is
        # the y of the baseline.
        let y1 { $y - $asc - $parms(opaquepadding)   }
        let ht { $asc + 2*$parms(opaquepadding)      }

        # NEXT, draw the rectangle
        pixane color     $pix $parms(bg)
        pixane rectangle $pix $x1 $y1 $wid $ht
        pixane color     $pix $parms(fg)

        # NEXT, draw the text
        pixane text $pix $x $y        \
            -text    $text            \
            -font    $page(hfont)     \
            -size    $parms(fontsize) \
            -align   $align           \
            -valign  baseline
    }


    #-------------------------------------------------------------------
    # Utility Procs

    # StripLine text
    #
    # text    A block of text
    #
    # Strips leading and trailing whitespace, converts newlines to spaces,
    # and replaces all multiple internal spaces with single spaces.
    #
    # TBD: Add this to a text processing module in marsutil(n).

    proc StripLine {text} {
        set text [string trim $text]
        regsub -all "\n" $text " " text
        regsub -all { +} $text " " text
        
        return $text
    }
    
    # WrapText width text
    #
    # width   desired width, in pixels
    # text    A text string
    #
    # Wrapping the text to the desired width given the font, and
    # returns a list of the lines.
    
    proc WrapText {width text} {
        set lines [list]
        set words [list]

        foreach word [split [StripLine $text] " "] {
            set line [join [concat $words $word] " "]

            lassign [pixfont measure $page(hfont) $parms(fontsize) $line] \
                wid asc desc

            if {$wid <= $width} {
                lappend words $word
                continue
            }

            # This word makes it too long
            lappend lines [join $words " "]
            set words [list $word]
        }

        lappend lines [join $words " "]

        return $lines
    }
}
