#-----------------------------------------------------------------------
# FILE: plant.tcl
#
#   Athena Infrastructure Plant Model singleton
#
# PACKAGE:
#   app_sim(n) -- athena_sim(1) implementation package
#
# PROJECT:
#   Athena S&RO Simulation
#
# AUTHOR:
#   Dave Hanks 
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# plant 
#
# athena_sim(1): Infrastructure Plant Model, main module.
#
# This module is responsible for allowing the user to specify the shares
# each agent in Athena owns in each neighborhood and compute the number and
# laydown of plants each agent has based upon those shares.  It is also
# responsible for degrading the repair level of plants based upon the 
# amount of repair (or lack thereof) each actor undertakes in keeping 
# their allocation of plants in operation.
#
# Note that plants owned by the SYSTEM agent are automatically kept at
# their initial state of repair and do not need to be maintained.
#
#-----------------------------------------------------------------------

snit::type plant {
    # Make it a singleton
    pragma -hasinstances no

    typevariable optParms {
        rho    ""
        shares ""
    }

    typevariable pfrac -array {}

    #-------------------------------------------------------------------
    # Scenario Control

    # start
    #
    # Computes the allocation of plants at scenario lock.

    typemethod start {} {
        # FIRST, fill in any neighborhoods that are not specified in the
        # shares table with the SYSTEM agent
        set nbhoods [nbhood names]

        foreach n $nbhoods {
            if {![rdb exists {SELECT * FROM plants_shares WHERE n=$n}]} {
                rdb eval {
                    INSERT INTO plants_shares(n, a, num, rho)
                    VALUES($n, 'SYSTEM', 1, 1.0);
                }
            }
        }

        # NEXT, compute adjusted population based on pcf
        set adjpop [rdb onecolumn {SELECT total(nbpop*pcf) FROM plants_n_view}]

        # NEXT, set the fraction of plants by nbhood
        rdb eval {
            SELECT n, pcf, nbpop FROM plants_n_view
        } row {
            let pfrac($row(n)) {$row(nbpop)*$row(pcf)/$adjpop}
        }

        # NEXT, populate the plants_na table.
        rdb eval {
            INSERT INTO plants_na(n, a, rho)
            SELECT n, 
                   a,
                   rho
            FROM plants_shares;
        }

        # NEXT, laydown plants in neighborhoods
        if {![parmdb get econ.disable]} {
            $type LaydownPlants
        } else {
            log warning plant "econ is disabled"
        }
    }

    # LaydownPlants
    #
    # This method computes the actual number of plants needed by
    # neighborhood and agent based upon initial repair level. The
    # actual repair level is then computed since, in general, there
    # will be more capacity than is needed because fractional plants
    # are not allowed.

    typemethod LaydownPlants {} {
        # FIRST, get the amount of goods each plant is capable of producing
        # at max capacity
        set goodsPerPlant [money validate [parmdb get plant.bktsPerYear.goods]]

        # NEXT, get the calibrated values from the CGE for the quantity of
        # goods baskets and their price
        set QSgoods [dict get [econ get] Cal::QS.goods]
        set Pgoods  [dict get [econ get] Cal::P.goods]

        # NEXT, adjust the the maximum number of goods baskets that could
        # possible be produced given that the initial capacity of the 
        # goods sector may be degraded
        let initCapFrac {[parmdb get econ.initCapPct]/100.0}
        let maxBkts     {$QSgoods / $Pgoods / $initCapFrac}
        
        # NEXT, go through the neighborhoods laying down plants for each
        # agent that owns them
        foreach n [nbhood names] {
            # NEXT, if no plants in the neighborhood nothing to do
            if {$pfrac($n) == 0.0} {
                continue
            }

            # NEXT, compute the total shares of plants in the 
            # neighborhood for all agents
            set tshares [rdb onecolumn {
                SELECT total(num) FROM plants_shares
                WHERE n=$n
            }]

            # NEXT, compute the maximum number of goods baskets
            # that could be made in this neighborhood
            let maxBktsN {$pfrac($n)*$maxBkts}

            # NEXT, go through each agent in the neighborhood assigning
            # the appropriate number of plants to each one based on 
            # shares and initial repair level
            rdb eval {
                SELECT a, num, rho FROM plants_shares
                WHERE n=$n
            } {
                # The fraction of plants this agent gets
                let afrac {double($num) / double($tshares)}

                # The number of plants this agent needs in this neighborhood
                # to produce the number of baskets required if they were
                # operating at 100% repair level
                let plantsNA {($maxBktsN * $afrac) / $goodsPerPlant}

                # The actual number of plants given the repair level and
                # that fractional plants do not exist
                # Note: floor() could be used here, resulting in an increase
                # to rho, but then that leaves the possiblity of a rho > 1.0
                if {$rho == 0.0} {
                    let actualPlantsNA {entier(ceil($plantsNA))}
                    set adjRho 0.0
                } else {
                    let actualPlantsNA {entier(ceil($plantsNA/$rho))}
                    # The actual repair level
                    let adjRho {($plantsNA) / double($actualPlantsNA)}
                }

                rdb eval {
                    UPDATE plants_na
                    SET num = $actualPlantsNA,
                        rho = $adjRho
                    WHERE n=$n AND a=$a
                }
            }
        }
    }

    #-----------------------------------------------------------------------
    # Infrastructure degradation

    # degrade
    #
    # This method applies a week's worth of degradation to all the plants
    # not owned by the SYSTEM agent, which do not degrade and require no
    # repair.  If plants owned by actors are not maintained via the 
    # MAINTAIN tactic, they will produce less and less affecting the 
    # capacity of the goods sector.

    typemethod degrade {} {
        # FIRST, if the econ model is disabled, do nothing
        if {[parmdb get econ.disable]} {
            return
        }

        # NEXT, get the plant lifetime
        set lt [parmdb get plant.lifetime]

        # NEXT, if the lifetime is zero, degradation is disabled
        if {$lt == 0} {
            return
        }

        # NEXT, the inverse of the lifetime is one weeks worth of 
        # degradation
        let deltaRho {1.0 / $lt}

        # NEXT, degrade repair levels, making sure they do not go 
        # negative
        # NOTE: Plants owned by the SYSTEM do not degrade
        rdb eval {
            UPDATE plants_na
            SET rho = max(rho - $deltaRho, 0.0)
            WHERE a != 'SYSTEM'
        }
    }

    #----------------------------------------------------------------------
    # Infrastructure repair

    # repairlevel n a cash
    #
    # n    - a neighborhood that contains manufacturing plants
    # a    - an actor that owns plants in n
    # cash - some amount of cash
    #
    # This method converts cash to some amount of repair and returns
    # the repair level that would result from the expenditure of that
    # cash on repairs
    
    typemethod repairlevel {n a cash} {
        # FIRST, get the number of plants
        set num [rdb eval {
                     SELECT num
                     FROM plants_na
                     WHERE n=$n AND a=$a
                 }]

        if {$num eq "" || $num == 0} {
            return 0.0
        }

        # NEXT, retrieve parms
        set bCost [money validate [parmdb get plant.buildcost]]
        set rFrac [parmdb get plant.repairfrac]

        # NEXT, the amount of money spent per plant
        let cashPerPlant {$cash / $num}

        # NEXT, the average amount of repair per plant that this amount
        # of money can do
        if {$rFrac == 0.0} {
            return 1.0
        } else {
            let dRho {$cashPerPlant / ($bCost * $rFrac)}
        }

        return $dRho
    }


    # repaircost n a lvl
    #
    # n     - a neighborhood that contains manufacturing plants
    # a     - an actor that owns some plants in n
    # dRho  - the desired change in level of repair
    #
    # This method computes the cost to repair all the plants owned by
    # actor a in neighborhood n for one weeks worth of repair or to the
    # requested level of repair, whichever is smaller.

    typemethod repaircost {n a dRho} {
        # FIRST, if the desired change is zero, no cost 
        if {$dRho == 0} {
            return 0.0
        }

        # FIRST get the number of plants 
        set num [rdb eval {
                      SELECT num 
                      FROM plants_na
                      WHERE n=$n AND a=$a
                }]

        if {$num eq "" || $num == 0} {
            return 0.0
        }

        # NEXT, retrieve parms
        set bCost [money validate [parmdb get plant.buildcost]]
        set rFrac [parmdb get plant.repairfrac]

        # NEXT, determine the cost of repairing one plant in this
        # neighborhood
        let maxCostPerWk {$bCost * $rFrac * $dRho}

        # NEXT, multiply by number of plants to get total cost 
        let totalCost {$maxCostPerWk * $num}

        return $totalCost 
    }

    # repair a nlist amount level 
    #
    # a     - an actor that owns infrastructure
    # n     - a neighborhood that a has infrastructure
    # dRho  - the change in level of repair for the plants
    #

    typemethod repair {a n dRho} {
        # FIRST, change rho by the amount requested
        rdb eval {
            UPDATE plants_na
            SET rho = min(1.0,rho + $dRho)
            WHERE n=$n AND a=$a
        }
    }

    # get  id ?parm?
    #
    # id      ID {n a} of a record in the plants_na table
    # parm    optional parm to retrieve from the record
    #
    # Returns the value of supplied parm from the requested record 
    # or a dictionary of parm/value pairs for the entire record.

    typemethod get {id {parm ""}} {
        lassign $id n a

        rdb eval {
            SELECT * FROM plants_na
            WHERE n=$n AND a=$a
        } row {
            if {$parm eq ""} {
                unset row(*)
                return [array get row]
            } else {
                return $row($parm)
            }
        }

        return ""
    }

    # validate id
    #
    # id    A list containing the neighborhood where plants are owned and
    #       the agent that owns them there.
    #
    # Validates a neighborhood/agent pair corresponding to plant ownership

    typemethod validate {id} {
        lassign $id n a

        if {![plant exists $id]} {
            return -code error -errorcode INVALID \
                "Invalid plant ID \"$id\"."
        }
        
        return $id
    }

    # exists  id
    #
    # id    A list containing the neighborhood where plants are owned and
    #       the agent that owns them there.
    #
    # Returns 1 if there are plants owned by the supplied agent, 0
    # otherwise.

    typemethod exists {id} {
        lassign $id n a

        return [rdb exists {
            SELECT * FROM plants_shares WHERE n=$n AND a=$a
        }]
    }


    # capacity total
    #
    # Returns the total output capacity of all manufacturing plants

    typemethod {capacity total} {} {
        set goodsPerPlant [money validate [parmdb get plant.bktsPerYear.goods]]

        set totBkts [rdb onecolumn {
            SELECT total(num*rho) FROM plants_na
        }]

        return [expr {$totBkts * $goodsPerPlant}]
    }

    # capacity n
    #
    # Returns the total output capacity of all manufacturing plants given
    # a neighborhood

    typemethod {capacity n} {n} {
        set goodsPerPlant [money validate [parmdb get plant.bktsPerYear.goods]]

        set totBkts [rdb onecolumn {
            SELECT total(num*rho) FROM plants_na
            WHERE n=$n
        }]

        return [expr {$totBkts * $goodsPerPlant}]
    }

    # capacity a
    #
    # Returns the total output capacity of all manufacturing plants given
    # an agent

    typemethod {capacity a} {a} {
        set goodsPerPlant [money validate [parmdb get plant.bktsPerYear.goods]]

        set totBkts [rdb onecolumn {
            SELECT total(num*rho) FROM plants_na
            WHERE a=$a
        }]

        return [expr {$totBkts * $goodsPerPlant}]
    }

    #-----------------------------------------------------------------------
    # Mutators
    #
    # Mutators are used to implement orders that change the scenario in
    # some way.  Mutators assume that their inputs are valid, and returns
    # a script of one or more commands that will undo the change.  When
    # change cannot be undone, the mutator returns the empty string.

    # mutate create parmdict
    #
    # parmdict     A dictionary of plant shares parms
    #
    #
    #    n       A neighborhood ID
    #    a       An agent ID, this may include 'SYSTEM'
    #    rho     The average repair level for plants owned by a in n
    #    shares  The number of shares of plants that a should own in n
    #            when the scenario is locked
    #
    # Creates a record in the rdb that will be used at scenario lock to 
    # determine the actual number of plants owned by a in n
    
    typemethod {mutate create} {parmdict} {
        dict with parmdict {}

        rdb eval {
            INSERT INTO plants_shares(n, a, rho, num)
            VALUES($n, $a, $rho, $num);
        }

        return [list rdb delete plants_shares "n='$n' AND a='$a'"]
    }

    # mutate delete id
    #
    # id   A neighborhood/agent pair that corresponds to a plant shares
    #      record that should be deleted.

    typemethod {mutate delete} {id} {
        lassign $id n a

        set data [rdb delete -grab plants_shares \
            {n=$n AND a=$a}]

        return [list rdb ungrab $data]
    }

    # mutate update parmdict
    #
    # parmdict   A dictionary of plant shares parameters
    #
    # id       A neighborhood/agent pair corresponding to a record that 
    #          should already exist.
    # rho      A repair level, or ""
    # num      The number of shares owned by a in n, or ""
    #
    # Updates a plant shares record in the database given the parms.

    typemethod {mutate update} {parmdict} {
        set parmdict [dict merge $optParms $parmdict]

        dict with parmdict {}

        lassign $id n a

        set data [rdb grab plants_shares {n=$n AND a=$a}]

        rdb eval {
            UPDATE plants_shares
            SET rho = nullif(nonempty($rho, rho), ''),
                num = nullif(nonempty($num, num), '')
            WHERE n=$n AND a=$a
        } {}
        
        return [list rdb ungrab $data]
    }

    #---------------------------------------------------------------------
    # Order Helpers

    # notAllocatedTo   a
    #
    # a     An agent
    #
    # This method returns a list of neighborhoods that do not have any
    # ownership of plants by the agent already specified.

    typemethod notAllocatedTo {a} {
        set nballoc [rdb eval {SELECT n FROM plants_shares WHERE a = $a}]

        set nbnotalloc [nbhood names]

        foreach n $nballoc {
            ldelete nbnotalloc $n
        }

        return $nbnotalloc
    }
}

#--------------------------------------------------------------------
# Orders:  PLANT:SHARES:*

# PLANT:SHARES:CREATE
#
# Creates an allocation of shares of manufacturing plants for an
# agent in a neighborhood.

order define PLANT:SHARES:CREATE {
    title "Allocate Production Capacity Shares"

    options -sendstates PREP

    form {
        rcc "Owning Agent:" -for a
        agent a 

        rcc "In Nbhood:" -for n
        enum n -listcmd {::plant notAllocatedTo $a}

        rcc "Initial Repair Frac:" -for rho
        frac rho -defvalue 1.0

        rcc "Shares:" -for num
        text num -defvalue 1
    }
} {

    prepare a      -toupper -required -type agent
    prepare n      -toupper -required -type nbhood
    prepare rho    -toupper           -type rfraction
    prepare num    -toupper           -type iquantity

    returnOnError

    # Cross check n 
    validate n {
        if {[plant exists [list $parms(n) $parms(a)]]} {
            reject n \
                "Agent $parms(a) already ownes a share of the plants in $parms(n)"
        }
    }

    returnOnError -final

    setundo [plant mutate create [array get parms]]
}

# PLANT:SHARES:DELETE
#
# Removes an allocation of shares from the database

order define PLANT:SHARES:DELETE {
    title "Delete Production Capacity Shares"

    options -sendstates PREP

    form {
        rcc "Record ID:" -for id
        plant id -context yes
    }
} {

    prepare id -toupper -required -type plant

    returnOnError -final

    setundo [plant mutate delete $parms(id)]
}

# PLANT:SHARES:UPDATE
#
# Updates an existing allocation of shares for an agent in a neighborhood

order define PLANT:SHARES:UPDATE {
    title "Update Production Capacity Shares"

    options -sendstates PREP
    
    form {
        rcc "ID:" -for id
        key id -context yes -table gui_plants_na \
            -keys {n a} \
            -loadcmd {orderdialog keyload id {rho num}}

        rcc "Initial Repair Frac:" -for rho
        frac rho 

        rcc "Shares:" -for num
        text num
    }
} {

    prepare id  -required -type plant
    prepare rho -toupper  -type rfraction
    prepare num -toupper  -type iquantity

    returnOnError -final

    set undo [list]
    lappend undo [plant mutate update [array get parms]]
    setundo [join $undo \n]
}

# PLANT:SHARES:UPDATE:MULTI
#
# Updates multiple allocations of shares for a list of agent/neighborhood
# pairs.

order define PLANT:SHARES:UPDATE:MULTI {
    title "Update Production Capacity Shares"

    options -sendstates PREP
    
    form {
        rcc "IDs:" -for ids
        multi ids -context yes -key id -table gui_plants_na \
            -loadcmd {orderdialog multiload ids *}

        rcc "Initial Repair Frac:" -for rho
        frac rho 

        rcc "Shares:" -for num
        text num
    }
} {

    prepare ids -required -listof plant
    prepare rho -toupper -type rfraction
    prepare num -toupper -type iquantity

    returnOnError -final

    foreach parms(id) $parms(ids) {
        lappend undo [plant mutate update [array get parms]]
    }

    setundo [join $undo \n]
}
