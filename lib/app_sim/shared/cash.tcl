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
    # Type Variables

    typevariable allocations -array {
        goods  0.0
        black  0.0
        pop    0.0
        region 0.0
        world  0.0
    }

    #-------------------------------------------------------------------
    # Public Methods


    # load
    #
    # Loads every actors' cash balances into working_cash for use
    # during strategy execution.  It also gives each actor his income.

    typemethod load {} {
        # FIRST, we should not be locking the scenario
        assert {![strategy locking]}

        # NEXT, clear the expenditures array.
        foreach sector [array names allocations] {
            set allocations($sector) 0.0
        }

        # NEXT, load up the working cash table, giving the actor his income.
        # and expending his overhead.
        rdb eval {
            DELETE FROM working_cash;
        }

        rdb eval {
            SELECT a, 
                   cash_reserve, 
                   income, 
                   cash_on_hand,
                   overhead
            FROM actors_view;
        } {
            let overheadDollars { $income * $overhead / 100.0 }

            $type Allocate overhead $overheadDollars

            let cash_on_hand { $cash_on_hand + $income - $overheadDollars }

            rdb eval {
                INSERT INTO working_cash(a, cash_reserve, income, cash_on_hand)
                VALUES($a, $cash_reserve, $income, $cash_on_hand)
            }
        }
    }

    # save
    #
    # Save every actors' cash balances back into the actors table.

    typemethod save {} {
        # FIRST, we should not be locking the scenario
        assert {![strategy locking]}

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

    # spend a eclass dollars
    #
    # a         - An actor
    # eclass    - An expenditure class, or NONE.
    # dollars   - Some number of dollars
    #
    # Deducts dollars from cash_on_hand if there are sufficient funds;
    # returns 1 on success and 0 on failure.  If the eclass is not NONE,
    # then the expenditure is allocated to the sectors.

    typemethod spend {a eclass dollars} {
        # FIRST, can he afford it?
        set cash_on_hand [cash get $a cash_on_hand]

        if {$dollars > $cash_on_hand} {
            return 0
        }

        # NEXT, expend it.
        rdb eval {
            UPDATE working_cash 
            SET cash_on_hand = cash_on_hand - $dollars
            WHERE a=$a
        }

        # NEXT, allocate the expenditure to the sectors.
        $type Allocate $eclass $dollars

        return 1
    }

    # refund a eclass dollars
    #
    # a         - An actor
    # eclass    - An expenditure class, or NONE.
    # dollars   - Some number of dollars
    #
    # Refunds dollars to the actor's cash on hand.  If the eclass is
    # not NONE, then the dollars are removed from the sector allocations.

    typemethod refund {a eclass dollars} {
        # FIRST, give him the money back.
        rdb eval {
            UPDATE working_cash 
            SET cash_on_hand = cash_on_hand + $dollars
            WHERE a=$a
        }

        # NEXT, the money no longer flows into the other sectors.
        $type Allocate $eclass [expr {-1.0*$dollars}]
    }

    # Allocate eclass dollars
    #
    # eclass   - An expenditure class, or NONE
    # dollars  - Some number of dollars.
    #
    # Allocates an expenditure of dollars to the CGE sectors.  If
    # the number of dollars is negative, the dollars are removed from
    # the sectors.  In any case, the dollars are allocated according
    # to the econ.shares.<class>.* parameter values.
    # 
    # If the eclass is NONE, this call is a no-op.

    typemethod Allocate {eclass dollars} {
        if {$eclass eq "NONE"} {
            return
        }

        foreach sector [array names allocations] {
            set frac [parm get econ.shares.$eclass.$sector]

            let allocations($sector) {$allocations($sector) + $frac*$dollars}
        }
    }

    # expenditures
    #
    # Returns a dictionary of the expenditures by sector.

    typemethod expenditures {} {
        return [array get allocations]
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

