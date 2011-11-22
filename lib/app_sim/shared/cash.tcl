#-----------------------------------------------------------------------
# TITLE:
#    cash.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Cash Management
#
#    This module is responsible for managing an actor's cash during
#    strategy execution.  It should only be used during the duration
#    of [strategy tock], or to set up for tactic tests in the test suite.
#
#-----------------------------------------------------------------------

snit::type cash {
    # Make it a singleton
    pragma -hasinstances no


    #-------------------------------------------------------------------
    # Public Methods

    # load
    #
    # Loads every actors' cash balances into working_cash for use
    # during strategy execution.  It also gives each actor his income.

    typemethod load {} {
        rdb eval {
            DELETE FROM working_cash;
            INSERT INTO working_cash(a, cash_reserve, income, cash_on_hand)
            SELECT a, cash_reserve, income, cash_on_hand + income FROM actors;
        }
    }

    # save
    #
    # Save every actors' cash balances back into the actors table.

    typemethod save {} {
        rdb eval {
            SELECT a, cash_reserve, cash_on_hand, gifts FROM working_cash
        } {
            rdb eval {
                UPDATE actors
                SET cash_reserve = $cash_reserve,
                    cash_on_hand = $cash_on_hand + $gifts
                WHERE a=$a
            }
        }

        rdb eval {
            DELETE FROM working_cash
        }
    }

    # get a parm
    #
    # a    - An actor
    # parm - A column name
    #
    # Retrieves a row dictionary, or a particular column value, from
    # working_cash

    typemethod get {a {parm ""}} {
        # FIRST, get the data
        rdb eval {SELECT * FROM working_cash WHERE a=$a} row {
            if {$parm ne ""} {
                return $row($parm)
            } else {
                unset row(*)
                return [array get row]
            }
        }

        return ""
    }

    # deposit a dollars
    #
    # a       - An actor
    # dollars - A positive number of dollars
    #
    # Moves dollars from cash_on_hand to cash_reserve, if there's
    # sufficient funds.  Returns 1 on success and 0 on failure.

    typemethod deposit {a dollars} {
        set cash_on_hand [cash get $a cash_on_hand]

        if {$dollars > $cash_on_hand} {
            return 0
        }

        rdb eval {
            UPDATE working_cash
            SET cash_reserve = cash_reserve + $dollars,
                cash_on_hand = cash_on_hand - $dollars
            WHERE a=$a;
        }

        return 1
    }

    # withdraw a dollars
    #
    # a       - An actor
    # dollars - A positive number of dollars
    #
    # Moves dollars from cash_reserve to cash_on_hand, if there's
    # sufficient funds.  Returns 1 on success and 0 on failure.

    typemethod withdraw {a dollars} {
        set cash_reserve [cash get $a cash_reserve]

        if {$dollars > $cash_reserve} {
            return 0
        }

        rdb eval {
            UPDATE working_cash 
            SET cash_reserve = cash_reserve - $dollars,
                cash_on_hand = cash_on_hand + $dollars
            WHERE a=$a;
        }

        return 1
    }

    # spend a dollars
    #
    # a         - An actor
    # dollars   - Some number of dollars
    #
    # Deducts dollars from cash_on_hand if there are sufficient funds;
    # returns 1 on success and 0 on failure.

    typemethod spend {a dollars} {
        set cash_on_hand [cash get $a cash_on_hand]

        if {$dollars > $cash_on_hand} {
            return 0
        }

        rdb eval {
            UPDATE working_cash 
            SET cash_on_hand = cash_on_hand - $dollars
            WHERE a=$a
        }

        return 1
    }

    # refund a dollars
    #
    # a         - An actor
    # dollars   - Some number of dollars
    #
    # Refunds dollars to the actor's cash on hand.

    typemethod refund {a dollars} {
        rdb eval {
            UPDATE working_cash 
            SET cash_on_hand = cash_on_hand + $dollars
            WHERE a=$a
        }
    }

    # give a dollars
    #
    # a         - An actor
    # dollars   - Some number of dollars
    #
    # Adds dollars to the actor's "gifts" balance; this will
    # be added to the actor's cash-on-hand when the working cash
    # is saved.  This allows us to give money to the actor that 
    # should only be available after this strategy execution is
    # complete.

    typemethod give {a dollars} {
        rdb eval {
            UPDATE working_cash 
            SET gifts = gifts + $dollars
            WHERE a=$a
        }
    }
}

