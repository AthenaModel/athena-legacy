#-----------------------------------------------------------------------
# TITLE:
#    sqldocument.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Extensible SQL Database Object
#
#    This module defines the sqldocument(n) type.  Each instance 
#    of the type can wrap a single SQLite3 database handle, providing
#    access to all of the database handle's subcommands as well as
#    addition subcommands of its own.
#
#    Access to the database is document-centric: open/create the 
#    database, read and write until an appropriate save point is 
#    reached, then commit all changes.  In other words, it's expected
#    that any given database file has but one writer at a time, and
#    arbitrarily many writes are batched into a single transaction.
#    (Otherwise, each write would be a single transaction, and the necessary
#    locking and unlocking would cause a performance hit.)
#
#    sqldocument(n) can be used to open and query any kind of SQL 
#    database file.  It addition, it can also create databases with
#    the necessary schema definitions to support other modules,
#    called sqlsections.  Each such module must adhere to the 
#    sqlsection(i) interface.  All definitions for all loaded sqlsection(i)
#    modules will be included in the created databases.
#
#    An sqlsection(i) module can define the following things:
#
#    * Persistent schema definitions
#    * Temporary schema definitions
#    * Temporary data definitions
#    * SQL functions
#
#    sqlsection(i) modules register themselves with sqldocument(n) on
#    load; sqldocument(n) queries the sqlsection(i) modules for their
#    definitions on database open and clear.
#
#-----------------------------------------------------------------------

namespace eval ::marsutil:: {
    namespace export sqldocument
}

#-----------------------------------------------------------------------
# sqldocument

snit::type ::marsutil::sqldocument {
    #-------------------------------------------------------------------
    # sqlsection(i)
    #
    # The following routines implement the module's sqlsection(i)
    # interface.

    # sqlsection title
    #
    # Returns a human-readable title for the section

    typemethod {sqlsection title} {} {
        return "sqldocument(n)"
    }

    # sqlsection schema
    #
    # Returns the section's persistent schema definitions, if any.

    typemethod {sqlsection schema} {} {
        return ""
    }

    # sqlsection tempschema
    #
    # Returns the section's temporary schema definitions, if any.

    typemethod {sqlsection tempschema} {} {
        return ""
    }

    # sqlsection tempdata
    #
    # Returns the section's temporary data definitions, if any.

    typemethod {sqlsection tempdata} {} {
        return ""
    }

    # sqlsection functions
    #
    # Returns a dictionary of function names and command prefixes

    typemethod {sqlsection functions} {} {
        set functions [list]

        lappend functions dicteq    [list ::marsutil::dicteq]
        lappend functions dictget   [list ::marsutil::sqldocument::dictget]
        lappend functions dictglob  [list ::marsutil::dictglob]
        lappend functions error     [list ::error]
        lappend functions format    [list ::format]
        lappend functions joinlist  [list ::join]
        lappend functions nonempty  [myproc NonEmpty]
        lappend functions percent   [list ::marsutil::percent]
        lappend functions wallclock [list ::clock seconds]

        return $functions
   }


    #-------------------------------------------------------------------
    # Components

    component db   ;# The SQLite3 database command, or NullDatabase if none

    #-------------------------------------------------------------------
    # Options

    # -rollback
    #
    # If on, sqldocument(n) supports rollbacks.  Default is off.

    option -rollback        \
        -default off        \
        -readonly yes       \
        -type snit::boolean

    # -autotrans
    #
    # If on, a transaction is always open; data isn't saved until the
    # application calls "commit".  If off, the user is responsible for
    # transactions, and "commit" is a no-op.

    option -autotrans       \
        -default on         \
        -readonly yes       \
        -type snit::boolean

    # -clock
    #
    # Specifies a simclock.  If it exists, simclock-related functions
    # are defined.

    option -clock     \
        -default  ""  \
        -readonly yes


    # -commitcmd
    #
    # Specifies an optional callback command to be executed after the
    # database has been committed but before a new transaction is 
    # started.
    
    option -commitcmd \
        -default "" 

    #-------------------------------------------------------------------
    # Instance variables

    # Array of data variables:
    #
    # dbIsOpen      Flag: 1 if there is an open database, and 0
    #               otherwise.
    # dbFile        Name of the current database file, or ""
    # registry      List of registered sqlsection module names,
    #               in order of registration.

    variable info -array {
        dbIsOpen 0
        dbFile   {}
        registry ::marsutil::sqldocument
    }



    #-------------------------------------------------------------------
    # Constructor
    
    constructor {args} {
        # FIRST, we have no database; set the db component accordingly.
        set db [myproc NullDatabase]

        # NEXT, process options
        $self configurelist $args
    }


    #-------------------------------------------------------------------
    # Public Methods: sqlsection(i) registration

    # register section
    #
    # section     Fully qualified name of an sqlsection(i) module
    #
    # Registers the section for later use

    method register {section} {
        if {$section ni $info(registry)} {
            lappend info(registry) $section
        }
    }

    # sections
    #
    # Returns a list of the names of the registered sections

    method sections {} {
        return $info(registry)
    }


    #-------------------------------------------------------------------
    # Public Methods: Database Management

    # open ?filename?
    #
    # filename         database file name
    #
    # Opens the database file, creating it if necessary.  Does not
    # change the database in any way; use "clear" to initialize it.
    # If filename is not specified, will reopen the previous file, if any.
    
    method open {{filename ""}} {
        # FIRST, the database must not already be open!
        require {!$info(dbIsOpen)} "database is already open"

        # NEXT, get the file name.
        if {$filename eq ""} {
            require {$info(dbFile) ne ""} "database file name not specified"

            set filename $info(dbFile)
        }

        # NEXT, attempt to open the database and define the db component.
        # 
        # NOTE: since the db command is defined in the instance
        # namespace, it will be destroyed automatically when the
        # instance is destroyed.  Note that uncommitted updates will
        # *not* be saved.
        set db ${selfns}::db

        sqlite3 $db $filename

        # NEXT, set the hardware security requirement
        $db eval {
            -- We don't need to safeguard the database from 
            -- hardware errors.
            PRAGMA synchronous=OFF;

            -- Keep temporary data in memory
            PRAGMA temp_store=MEMORY;
        }

        # NEXT, if -rollback is off, turn off journaling.
        if {!$options(-rollback)} {
            $db eval {
                PRAGMA journal_mode=OFF;
            }
        }

        # NEXT, define the temporary tables
        $self DefineTempSchema
        $self DefineTempData

        # NEXT, define standard functions.
        $self DefineFunctions

        # NEXT, save the file name; we are in business
        set info(dbFile)   $filename
        set info(dbIsOpen) 1

        # NEXT, if -autotrans then open the initial transaction.
        if {$options(-autotrans)} {
            $db eval {BEGIN IMMEDIATE TRANSACTION;}
        }
    }

    # clear
    #
    # Initializes the database, clearing old content and redefining
    # the schema according to the registered list of sqlsections.

    method clear {} {
        # FIRST, are the requirements for clearing the database met?
        require {$info(dbIsOpen)}         "database is not open"

        # NEXT, Clear the current contents, if any, and set up the 
        # schema.  If the database is being written to by another
        # application, we will get a "database is locked" error.

        if {[catch {$self DefineSchema} result]} {
            if {$result eq "database is locked"} {
                error $result
            } else {
                error "could not initialize database: $result"
            }
        }
    }

    # DefineSchema
    #
    # Deletes old data from the database, and defines the proper schema.

    method DefineSchema {} {
        # FIRST, commit any open transaction.  If the commit fails, that's
        # no big deal.
        catch {$db eval {COMMIT TRANSACTION;}}

        # NEXT, open an exclusive transaction; if there's another
        # application attached to this database file, 
        # we'll get a "database is locked" error.
        $db eval {BEGIN EXCLUSIVE TRANSACTION}

        # NEXT, clear any old content
        sqlib clear $db

        # NEXT, define persistent schema entities
        foreach section $info(registry) {
            set schema [$section sqlsection schema]

            if {$schema ne ""} {
                $db eval $schema
            }
        }

        # NEXT, define temporary schema entities
        $self DefineTempSchema
        $self DefineTempData

        # NEXT, commit the schema changes
        $db eval {COMMIT TRANSACTION;}

        # NEXT, if -autotrans then begin an immediate transaction; we want 
        # there to be a transaction open at all times.  We'll commit the 
        # data to disk from time to time.

        if {$options(-autotrans)} {
            $db eval {BEGIN IMMEDIATE TRANSACTION;}
        }
    }

    # DefineTempSchema
    #
    # Define the temporary tables for the sqlsections included in
    # the registry.  This should be called on both "open"
    # and "clear", so that the temporary tables are always defined.

    method DefineTempSchema {} {
        foreach section $info(registry) {
            set schema [$section sqlsection tempschema]

            if {$schema ne ""} {
                $db eval $schema
            }
        }
    }

    # DefineTempData
    #
    # Define the temporary data for the sqlsections included in
    # the registry.  This should be called on both "open"
    # and "clear", so that the temporary tables are always populated
    # as required.

    method DefineTempData {} {
        foreach section $info(registry) {
            # FIRST, if the section does not define the tempdata 
            # subcommand, skip it.
            #
            # TBD: Once all existing sections are updated, this
            # check should be omitted, as it unduly constrains
            # the clients.
            if {[catch {
                if {"sqlsection tempdata" ni [$section info typemethods]} {
                    continue
                }
            }]} {
                continue
            }

            set content [$section sqlsection tempdata]

            foreach {table rows} $content {
                $db eval "DELETE FROM $table"

                foreach row $rows {
                    $self insert $table $row
                }
            }
        }
    }
    # DefineFunctions
    #
    # Define SQL functions.

    method DefineFunctions {} {
        # FIRST, define the -clock functions
        if {$options(-clock) ne ""} {
            $db function tozulu [list $options(-clock) toZulu]
            $db function now    [list $options(-clock) now]
        }

        # NEXT, define functions defined in sqlsections.
        foreach section $info(registry) {
            foreach {name definition} [$section sqlsection functions] {
                $db function $name $definition
            }
        }
    }

    # lock tables
    #
    # tables      A list of table names
    #
    # Creates triggers which effectively make the listed tables read-only.
    # It's OK if the tables are already locked.  Note that locking
    # a table doesn't prevent the database from being "clear"ed.
    #
    # NOTE: Doesn't support attached databases.

    method lock {tables} {
        require {$info(dbIsOpen)} "database is not open"

        foreach table $tables {
            foreach event {DELETE INSERT UPDATE} {
                $db eval [outdent "
                    CREATE TRIGGER IF NOT EXISTS
                    sqldocument_lock_${event}_${table} BEFORE $event ON $table
                    BEGIN SELECT error('Table \"$table\" is read-only'); END;
                "]
            }
        }
    }

    # unlock tables
    #
    # tables      A list of table names
    #
    # Deletes any lock triggers. It's OK if the tables are already unlocked.
    #
    # NOTE: Doesn't support attached databases.

    method unlock {tables} {
        require {$info(dbIsOpen)} "database is not open"

        foreach table $tables {
            foreach event {DELETE INSERT UPDATE} {
                $db eval [outdent "
                    DROP TRIGGER IF EXISTS sqldocument_lock_${event}_${table}
                "]
            }
        }
    }

    # islocked table
    # 
    # table      The name of a table
    #
    # Returns 1 if the table is locked, and 0 otherwise.
    #
    # Note: if a table is a temporary table, the lock triggers will
    # *automatically* be temporary triggers; otherwise they will be
    # persistent triggers.  Thus, we need to look into both the
    # sqlite_master and the sqlite_temp_master for matching triggers.
    #
    # NOTE: Doesn't support attached databases.
   
    method islocked {table} {
        # Just query whether the UPDATE trigger exists
        set trigger "sqldocument_lock_UPDATE_$table"

        $db exists {
            SELECT name FROM sqlite_master
            WHERE name=$trigger
            UNION
            SELECT name FROM sqlite_temp_master
            WHERE name=$trigger
        }
    }

    # commit
    #
    # Commits all database changes to the db, and opens a new 
    # transaction.  If -autotrans is off, this is a no-op.

    method commit {} {
        require {$info(dbIsOpen)} "database is not open"

        if {$options(-autotrans)} {
            # Break this up into two SQL statements. If one fails, its
            # easier to trace the problem.
            try {
                $db eval {
                    COMMIT TRANSACTION;
                }

                # If there is a commit command to be executed, do it.
                if {$options(-commitcmd) ne ""} {
                    if {[catch {uplevel \#0 $options(-commitcmd)} result]} {
                        bgerror "-commitcmd: $result"
                    }
                }
            } finally {
                $db eval {
                    BEGIN IMMEDIATE TRANSACTION;
                }
            }
        }
    }

    # close
    #
    # Commits all changes and closes the wsdb.  Once this is done,
    # the database must be opened before it can be used.

    method close {} {
        require {$info(dbIsOpen)} "database is not open"

        # Try to commit any changes; but if it's not possible, it's
        # not possible.
        catch {$db eval {COMMIT TRANSACTION;}}
        $db close

        set info(dbIsOpen) 0
        set db [myproc NullDatabase]
    }

    #-------------------------------------------------------------------
    # Public Methods: General database queries

    # Delegated methods
    delegate method query   to db using {::marsutil::sqlib %m %c} 
    delegate method tables  to db using {::marsutil::sqlib %m %c} 
    delegate method schema  to db using {::marsutil::sqlib %m %c} 
    delegate method mat     to db using {::marsutil::sqlib %m %c} 
    delegate method insert  to db using {::marsutil::sqlib %m %c}
    delegate method replace to db using {::marsutil::sqlib %m %c}
    delegate method *       to db

    # dbfile
    #
    # Returns the file name, if any

    method dbfile {} {
        return $info(dbFile)
    }

    # isopen
    #
    # Returns 1 if the database is open, and 0 otherwise.
    
    method isopen {} {
        return $info(dbIsOpen)
    }

    # saveas filename
    #
    # filename   A file name
    #
    # Saves a copy of the db to the specified file name.

    method saveas {filename} {
        # FIRST, if we have locked tables they need to be unlocked.
        set lockedTables [list]

        foreach table [$self tables] {
            if {[$self islocked $table]} {
                lappend lockedTables $table
                $self unlock $table
            }
        }

        # NEXT, there can't be any open transaction, so commit.
        catch {
            $db eval {COMMIT TRANSACTION;}
        }

        # NEXT, try to save the data.
        try {
            sqlib saveas $db $filename
        } finally {
            # And now, make sure we lock the tables and open
            # transaction (if need be)
            $self lock $lockedTables
            
            if {$options(-autotrans)} {
                $db eval {BEGIN IMMEDIATE TRANSACTION;}
            }
        }

        return
    }

    #-------------------------------------------------------------------
    # SQL Functions

    # NonEmpty args...
    #
    # args...    A list of one or more arguments
    #
    # Returns the first argument that isn't "".  Like COALESCE(),
    # but treats "" like NULL.

    proc NonEmpty {args} {
        foreach arg $args {
            if {$arg ne ""} {
                return $arg
            }
        }

        return ""
    }

    #-------------------------------------------------------------------
    # Utility Procs

    # dictget dict key
    #
    # Returns a value from a dictionary, or "" if the key isn't found.

    proc dictget {dict key} {
        if {[dict exists $dict $key]} {
            return [dict get $dict $key]
        } else {
            return ""
        }
    }

    # NullDatabase args
    #
    # args       Arguments to the db component.  Ignored.
    #
    # Used as the db component when no database is open.  Causes all 
    # methods delegated to the db to be rejected with a good error
    # message

    proc NullDatabase {args} {
        return -code error "database is not open"
    }
}





